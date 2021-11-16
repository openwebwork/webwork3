<template>
	<q-card v-if="problemText" class="bg-grey-3">
		<q-card-section v-if="problem_type=='library'">
			<q-btn-group push>
				<q-btn size="sm" push icon="add" @click="$emit('addProblem')" />
				<q-btn size="sm" push icon="edit" />
				<q-btn size="sm" push icon="shuffle" />
			</q-btn-group>
		</q-card-section>

		<q-card-section v-if="answerTemplate" class="q-pa-sm bg-white">
			<div ref="answerTemplateDiv" v-html="answerTemplate" class="pg-answer-template-container" />
		</q-card-section>
		<q-separator v-if="answerTemplate" />
		<q-card-section class="q-pa-sm">
			<div ref="problemTextDiv" v-html="problemText" class="pg-problem-container" />
		</q-card-section>
		<q-separator v-if="submitButtons.length"/>
		<q-card-actions class="q-pa-sm bg-white" v-if="submitButtons.length">
			<q-btn v-for="button in submitButtons" :key="button.name" :name="button.name"
				:id="`${problemPrefix}${button.name}`" type="submit" :form="`${problemPrefix}problemMainForm`"
				color="primary" @click="submitButton = button" no-caps>
				{{ button.value }}
			</q-btn>
		</q-card-actions>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted, nextTick } from 'vue';
import type { SubmitButton } from 'src/typings/renderer';
import { fetchProblem } from 'src/APIRequests/renderer';
import { RENDER_URL } from 'src/constants';
import * as bootstrap from 'bootstrap';
import type JQueryStatic from 'jquery';
import JQuery from 'jquery';
import { logger } from 'src/boot/logger';

import typeset from './mathjax-config';

declare global {
	interface Window {
		// eslint-disable-next-line @typescript-eslint/no-explicit-any
		MathJax: any
		$?: JQueryStatic;
		jQuery?: JQueryStatic;
		bootstrap?: typeof bootstrap;
	}
}

window.$ = window.jQuery = JQuery;
window.bootstrap = bootstrap;

export default defineComponent({
	name: 'Problem',
	props: {
		sourceFilePath: {
			type: String,
			default: ''
		},
		problemPrefix: {
			type: String,
			default: ''
		},
		raw_source: {
			type: String,
			default: ''
		},
		type: {
			type: String,
			default: ''
		},
		problemType: {
			type: String,
			default: 'library'
		}
	},
	emits: ['addProblem'],
	setup(props) {
		const problemText = ref('');
		const answerTemplate = ref('');
		const file = ref(props.sourceFilePath);
		const problem_type = ref(props.problemType);
		const problemTextDiv = ref<HTMLElement>();
		const answerTemplateDiv = ref<HTMLElement>();
		const submitButtons = ref<Array<SubmitButton>>([]);
		const submitButton = ref<SubmitButton>();
		const activePopovers: Array<InstanceType<typeof bootstrap.Popover>> = [];

		const loadResource = async (src: string, id?: string) => {
			return new Promise<void>((resolve, reject) => {
				let shouldAppend = false;
				let el: HTMLScriptElement | HTMLLinkElement | null;
				if (/\.js(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
					el = document.querySelector(`script[src="${src}"]`);
					if (!el) {
						el = document.createElement('script');
						if (id) el.id = id;
						el.async = false;
						el.src = src;
						shouldAppend = true;
					}
				} else if (/\.css(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
					el = document.querySelector(`link[href="${src}"]`);
					if (!el) {
						el = document.createElement('link');
						el.rel = 'stylesheet';
						el.href = src;
						shouldAppend = true;
					}
				} else {
					reject();
					return;
				}

				if (el.dataset.loaded) {
					resolve();
					return;
				}

				el.addEventListener('error', reject);
				el.addEventListener('abort', reject);
				el.addEventListener('load', () => {
					if (el) el.dataset.loaded = 'true';
					resolve();
				});

				if (shouldAppend) document.head.appendChild(el);
			});
		};

		const clearUI = () => {
			problemText.value = '';
			answerTemplate.value = '';
			submitButtons.value = [];
		};

		const loadProblem = async (url: string, formData: FormData, overrides: { [key: string]: string }) => {
			// Make sure that any popovers left open from a previous rendering are removed.
			for (const popover of activePopovers) {
				popover.dispose();
			}
			activePopovers.length = 0;

			if (!file.value) {
				clearUI();
				return;
			}

			const { renderedHTML, js, css, renderError } = await fetchProblem(url, formData, overrides);

			if (!renderedHTML || !renderedHTML.problemText) {
				clearUI();
				if (renderError) problemText.value = renderError;
				return;
			}

			await Promise.all(css.map(
				async (cssSource) => {
					await loadResource(cssSource).
						catch(() => logger.log('error', `Could not load ${cssSource}`));
				}
			));

			await Promise.all(js.map(
				async (jsSource) => {
					await loadResource(jsSource).
						catch(() => logger.log('error', `Could not load ${jsSource}`));
				}
			));

			problemText.value = renderedHTML.problemText;
			answerTemplate.value = renderedHTML.answerTemplate ?? '';
			submitButtons.value = renderedHTML.submitButtons ?? [];

			await nextTick();

			const outputDivs: Array<HTMLElement> = [];
			if (problemTextDiv.value) outputDivs.push(problemTextDiv.value);
			if (answerTemplateDiv.value) outputDivs.push(answerTemplateDiv.value);

			await typeset(outputDivs);

			// Execute any scripts in the pg output.
			for (const div of outputDivs) {
				div.querySelectorAll('script').forEach((origScript) => {
					if (origScript.type && /^math\/tex/.test(origScript.type)) return;
					const newScript = document.createElement('script');
					Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
					newScript.appendChild(document.createTextNode(origScript.innerHTML));
					origScript.parentNode?.replaceChild(newScript, origScript);
				});
			}

			await nextTick();

			// Activate the popovers in the results table.
			answerTemplateDiv.value?.querySelectorAll('.answer-preview[data-bs-toggle="popover"]')
				.forEach((preview) => {
					if ((preview as HTMLElement).dataset.bsContent)
						activePopovers.push(new bootstrap.Popover(preview));
				});

			window.dispatchEvent(new Event('PGContentLoaded'));

			insertNativeListeners();
		};

		const problemForm = ref<HTMLFormElement>();

		// Add listeners to native form elements in the problem.
		const insertNativeListeners = () => {
			problemForm.value = problemTextDiv.value?.querySelector('form[name=problemMainForm]') as HTMLFormElement;
			if (!problemForm.value) {
				logger.log('error', 'NO PROBLEM FORM FOUND');
				return;
			}

			problemForm.value.id = `${props.problemPrefix}problemMainForm`;

			// Add a click handler to any submit buttons in the problem form.
			// Some Geogebra problems add one of these for example.
			problemForm.value.querySelectorAll('input[type=submit]').forEach((button) => {
				button.addEventListener('click', () => {
					const inputBtn = button as HTMLInputElement;
					submitButton.value = { name: inputBtn.name, value: inputBtn.value };
				});
			});

			problemForm.value.addEventListener('submit', (e) => {
				e.preventDefault();
				if (!submitButton.value) {
					logger.log('error', 'No button was pressed...');
					return;
				}
				void loadProblem(problemForm.value?.action ?? RENDER_URL, new FormData(problemForm.value), {
					[submitButton.value.name]: submitButton.value.value,
					// Again, we should not be overriding these on the frontend
					problemSeed: '12345',
					outputFormat: 'ww3',
					showPreviewButton: '1',
					showCheckAnswersButton: '1',
					showCorrectAnswersButton: '1',
					answerPrefix: props.problemPrefix
				});
			});
		};

		const initialLoad = () => {
			file.value = props.sourceFilePath;
			void loadProblem(RENDER_URL, new FormData(), {
				// We should not be overriding these on the frontend.
				problemSeed: '12345',
				sourceFilePath: file.value,
				outputFormat: 'ww3',
				showPreviewButton: '1',
				showCheckAnswersButton: '1',
				showCorrectAnswersButton: '1',
				answerPrefix: props.problemPrefix
			});
		};

		watch(() => props.sourceFilePath, initialLoad);

		onMounted(async () => {
			await Promise.all([
				'js/MathQuill/mathquill.css',
				'js/MathQuill/mqeditor.css',
				'js/ImageView/imageview.css',
				'js/Knowls/knowl.css'
			].map(
				async (cssSource) => {
					await loadResource(cssSource).
						catch(() => logger.log('error', `Could not load ${cssSource}`));
				}
			));

			await Promise.all(([
				['mathjax/tex-chtml.js', 'MathJax-script'],
				['js/MathQuill/mathquill.js'],
				['js/MathQuill/mqeditor.js'],
				['js/ImageView/imageview.js'],
				['js/Knowls/knowl.js'],
				['js/InputColor/color.js']
			] as Array<[string, string?]>).map(
				async (jsSource) => {
					await loadResource(...jsSource).
						catch(() => logger.log('error', `Could not load ${jsSource[0]}`));
				}
			));

			await nextTick();

			if (props.sourceFilePath) initialLoad();
		});

		return {
			problem_type,
			problemText,
			problemTextDiv,
			answerTemplate,
			answerTemplateDiv,
			submitButtons,
			submitButton
		};
	}
});
</script>

<style lang="scss">
@import "src/css/bootstrap";
</style>

<style lang="scss" scoped>
@use "src/css/pg.scss";
</style>

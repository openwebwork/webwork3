<template>
	<q-card v-if="problemText" class="bg-grey-3">
		<q-card-section v-if="answerTemplate" class="q-pa-sm bg-white">
			<div ref="answerTemplateDiv" v-html="answerTemplate" class="pg-answer-template-container" />
		</q-card-section>
		<q-separator v-if="answerTemplate" />
		<q-card-section class="q-pa-sm">
			<div ref="problemTextDiv" v-html="problemText" class="pg-problem-container" />
		</q-card-section>
		<q-separator v-if="submitButtons.length"/>
		<q-card-actions class="q-pa-sm bg-white" v-if="submitButtons.length">
			<q-btn v-for="button of submitButtons" :key="button.name" :name="button.name" :id="button.name"
				type="submit" form="problemMainForm" color="primary" @click="submitButton = button" no-caps>
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

import './mathjax-config';

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
		file: {
			type: String,
			default: ''
		}
	},
	setup(props) {
		const problemText = ref('');
		const answerTemplate = ref('');
		const _file = ref(props.file);
		const problemTextDiv = ref<HTMLElement>();
		const answerTemplateDiv = ref<HTMLElement>();
		const submitButtons = ref<Array<SubmitButton>>([]);
		const submitButton = ref<SubmitButton>();

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

				if (el.dataset.dataLoaded) {
					resolve();
					return;
				}

				el.addEventListener('error', reject);
				el.addEventListener('abort', reject);
				el.addEventListener('load', () => {
					if (el) el.dataset.dataLoaded = 'true';
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

		const loadProblem = async (formData: FormData, url: string, overrides: { [key: string]: string }) => {
			if (!_file.value) {
				clearUI();
				return;
			}

			const { renderedHTML, js, css, renderError } = await fetchProblem(formData, url, overrides);

			if (!renderedHTML || !renderedHTML.problemText) {
				clearUI();
				if (renderError) problemText.value = renderError;
				return;
			}

			await Promise.all(css.map(
				async (cssSource) => {
					await loadResource(cssSource).
						catch(() => { /* console.error(`Could not load ${cssSource}`) */ });
				}
			));

			await Promise.all(js.map(
				async (jsSource) => {
					await loadResource(jsSource).
						catch(() => { /* console.error(`Could not load ${jsSource}`) */ });
				}
			));

			problemText.value = renderedHTML.problemText;
			answerTemplate.value = renderedHTML.answerTemplate ?? '';
			submitButtons.value = renderedHTML.submitButtons ?? [];

			let outputDivs: Array<HTMLElement> = [];

			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise(outputDivs));
			}

			await nextTick();

			if (problemTextDiv.value) outputDivs.push(problemTextDiv.value);
			if (answerTemplateDiv.value) outputDivs.push(answerTemplateDiv.value);

			// Execute any scripts in the pg output.
			for (const div of outputDivs) {
				div.querySelectorAll('script').forEach((origScript) => {
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
						new bootstrap.Popover(preview);
				});

			window.dispatchEvent(new Event('PGContentLoaded'));

			insertNativeListeners();
		};

		// Add listeners to native form elements in the problem.
		const insertNativeListeners = () => {
			const problemForm = problemTextDiv.value?.querySelector('form#problemMainForm') as HTMLFormElement;

			if (!problemForm) {
				// console.error('NO PROBLEM FORM FOUND');
				return;
			}

			// Add a click handler to any submit buttons in the problem form.
			// Some Geogebra problems add one of these for example.
			problemForm.querySelectorAll('input[type=submit]').forEach((button) => {
				button.addEventListener('click', () => {
					const inputBtn = button as HTMLInputElement;
					submitButton.value = { name: inputBtn.name, value: inputBtn.value };
				});
			});

			problemForm.addEventListener('submit', (e) => {
				e.preventDefault();
				if (!submitButton.value) {
					// console.error('No button was pressed...');
					return;
				}
				void loadProblem(new FormData(problemForm), problemForm.action ?? RENDER_URL, {
					[submitButton.value.name]: submitButton.value.value,
					// Again, we should not be overriding these on the frontend
					problemSeed: '12345',
					outputFormat: 'ww3',
					showPreviewButton: '1',
					showCheckAnswersButton: '1',
					showCorrectAnswersButton: '1'
				});
			});
		};

		watch(() => props.file, () => {
			_file.value = props.file;
			void loadProblem(new FormData(), RENDER_URL, {
				// We should not be overriding these on the frontend.
				problemSeed: '12345',
				sourceFilePath: _file.value,
				outputFormat: 'ww3',
				showPreviewButton: '1',
				showCheckAnswersButton: '1',
				showCorrectAnswersButton: '1'
			});
		});

		onMounted(async () => {
			await Promise.all([
				'js/MathQuill/mathquill.css',
				'js/MathQuill/mqeditor.css',
				'js/ImageView/imageview.css',
				'js/Knowls/knowl.css'
			].map(
				async (cssSource) => {
					await loadResource(cssSource).
						catch(() => { /* console.error(`Could not load ${cssSource}`) */ });
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
						catch(() => { /* console.error(`Could not load ${jsSource.src}`) */ });
				}
			));
		});

		return {
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

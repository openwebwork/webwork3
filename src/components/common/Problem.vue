<template>
	<q-card v-if="problemText" class="bg-grey-3">
		<q-card-section v-if="problem_type === 'LIBRARY'">
			<q-btn-group push>
				<q-btn size="sm" push icon="add" @click="$emit('addProblem')" />
				<q-btn size="sm" push icon="edit" />
				<q-btn size="sm" push icon="description" @click="show_path = !show_path"/>
				<q-btn size="sm" push icon="shuffle" @click="freeProblem.rerandomize()"/>
			</q-btn-group>
		</q-card-section>

		<q-card-section v-if="problem_type === 'SET'">
			<span class="div-h6 problem-number">{{freeProblem.problem_number}}</span>
			<q-btn-group push>
				<q-btn size="sm" icon="height" class="move-handle" />
				<q-btn size="sm" push icon="delete" @click="$emit('removeProblem',freeProblem)" />
				<q-btn size="sm" push icon="edit" />
				<q-btn size="sm" push icon="description" @click="show_path = !show_path"/>
				<q-btn size="sm" push icon="shuffle" @click="freeProblem.rerandomize()"/>
			</q-btn-group>
		</q-card-section>

		<q-card-section v-if="show_path">
			file path: {{ freeProblem.path() }}
		</q-card-section>

		<q-separator v-if="problem_type === 'LIBRARY' || problem_type === 'SET'" />

		<q-card-section v-if="answerTemplate" class="q-pa-sm bg-white">
			<div ref="answerTemplateDiv" v-html="answerTemplate" class="pg-answer-template-container" />
		</q-card-section>

		<q-separator v-if="answerTemplate" />

		<q-card-section v-if="problemText===''">
			<div><q-spinner-ios color="primary" size="2em" /></div>
		</q-card-section>
		<q-card-section class="q-pa-sm pg-problem-container" v-else>
			<div ref="problemTextDiv" v-html="problemText" />
		</q-card-section>

		<q-separator v-if="submitButtons.length"/>

		<q-card-actions class="q-pa-sm bg-white" v-if="submitButtons.length">
			<q-btn v-for="button in submitButtons"
				:key="button.name" :name="button.name"
				:id="`${freeProblem.renderer_params.answerPrefix}${button.name}`"
				type="submit" :form="`${freeProblem.renderer_params.answerPrefix}problemMainForm`"
				color="primary" @click="submitButton = button" no-caps>
				{{ button.value }}
			</q-btn>
		</q-card-actions>
	</q-card>
</template>

<script lang="ts">
import type { PropType } from 'vue';
import { defineComponent, ref, watch, onMounted, nextTick } from 'vue';
import type { RendererParams, SubmitButton } from 'src/common/api-requests/renderer';
import { fetchProblem } from 'src/common/api-requests/renderer';
import { RENDER_URL } from 'src/common/constants';
import * as bootstrap from 'bootstrap';
import type JQueryStatic from 'jquery';
import JQuery from 'jquery';
import { logger } from 'boot/logger';

import typeset from './mathjax-config';
import { Problem } from 'src/store/models/problems';

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
		problem: {
			type: Object as PropType<Problem>,
			default: new Problem()
		},
	},
	emits: ['addProblem', 'storeRenderedProblem', 'removeProblem'],
	setup(props) {
		const problemText = ref('');
		const answerTemplate = ref('');
		const freeProblem = ref<Problem>(props.problem.clone());
		const problem_type = ref(props.problem.problem_type);
		const problemTextDiv = ref<HTMLElement>();
		const answerTemplateDiv = ref<HTMLElement>();
		const submitButtons = ref<Array<SubmitButton>>([]);
		const submitButton = ref<SubmitButton>();
		const activePopovers: Array<InstanceType<typeof bootstrap.Popover>> = [];

		logger.debug(`[Problem/setup] file: ${freeProblem.value.path()}, type: ${freeProblem.value.problem_type}`);
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
			logger.debug('[Problem/clearUI]');
			problemText.value = '';
			answerTemplate.value = '';
			submitButtons.value = [];
		};

		watch(() => props.problem, () => {
			freeProblem.value = props.problem.clone();
		}, { deep: true });

		const loadProblem = async (url: string, formData: FormData, overrides: RendererParams) => {
			// Make sure that any popovers left open from a previous rendering are removed.
			for (const popover of activePopovers) {
				popover.dispose();
			}
			activePopovers.length = 0;

			if (!freeProblem.value.path()) {
				clearUI();
				return;
			}

			const { renderedHTML, js, css, renderError } = await fetchProblem(url, formData, overrides);

			if (!renderedHTML || !renderedHTML.problemText) {
				clearUI();
				if (renderError) problemText.value = renderError;
				return;
			}

			await Promise.all((css).map(
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
				logger.error('NO PROBLEM FORM FOUND');
				return;
			}

			problemForm.value.id = `${freeProblem.value.renderer_params.answerPrefix || ''}problemMainForm`;

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
					logger.error('No button was pressed...');
					return;
				}
				void loadProblem(problemForm.value?.action ?? RENDER_URL, new FormData(problemForm.value), {
					[submitButton.value.name]: submitButton.value.value,
					...freeProblem.value.requestParams()
				});
			});
		};

		const initialLoad = () => {
			logger.debug('[Problem/initialLoad] I have been called.');
			void loadProblem(RENDER_URL, new FormData(), freeProblem.value.requestParams());
		};

		watch(freeProblem, initialLoad, { deep: true });

		onMounted(async () => {
			// Load MathJax
			await loadResource('mathjax/tex-chtml.js', 'MathJax-script')
				.catch(() => logger.log('error', 'Could not load mathjax/tex-chtml.js'));

			await nextTick();

			// aren't we already watching for this??
			if (freeProblem.value.path()) {
				logger.debug('[Problem/onMounted] calling initialLoad...');
				initialLoad();
			};
		});

		return {
			problem_type,
			problemText,
			problemTextDiv,
			answerTemplate,
			answerTemplateDiv,
			submitButtons,
			submitButton,
			freeProblem,
			show_path: ref(false)
		};
	}
});
</script>

<style lang="scss">
@import "src/css/bootstrap";
</style>

<style lang="scss" scoped>
.pg-problem-container {
	background-color: #f5f5f5;

	// Override a few of the styles from the dynamically loaded problem.css

	:deep(.problem-main-form) {
		margin: 0;
	}

	:deep(.problem-content) {
		border: none;
		box-shadow: unset;
		margin: 0;
	}
}

// Answer template

:deep(.pg-answer-template-container) {
	// We don't have the bootstrap mb-2 class, so add its style.

	.mb-2 {
		margin-bottom: 0.5rem !important;
	}
}

.problem-number {
	border: 1px black solid;
	padding: 3px;
}
</style>

<template>
	<q-card v-if="problemText" class="bg-grey-3">
		<q-card-section v-if="answerTemplate" class="q-pa-sm bg-white">
			<div ref="answerTemplateDiv" v-html="answerTemplate" class="pg-answer-template-container" />
		</q-card-section>
		<q-separator v-if="answerTemplate" />
		<q-card-section class="q-pa-sm">
			<div ref="problemTextDiv" v-html="problemText" class="pg-problem-container" />
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted, nextTick } from 'vue';
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

		const loadProblem = async (formData: FormData, url: string, overrides: { [key: string]: string }) => {
			if (!_file.value) {
				problemText.value = '';
				answerTemplate.value = '';
				return;
			}

			const { renderedHTML, js, css } = await fetchProblem(formData, url, overrides);

			if (!renderedHTML) return;

			if (typeof renderedHTML === 'string') {
				problemText.value = renderedHTML;
				return;
			}

			if (!renderedHTML.problemText) return;

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

			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([problemTextDiv.value]));
				if (answerTemplate.value)
					// eslint-disable-next-line @typescript-eslint/no-unsafe-return
					window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([answerTemplateDiv.value]));

			}

			await nextTick();

			// Execute any scripts in the pg output.
			problemTextDiv.value?.querySelectorAll('script').forEach((origScript) => {
				const newScript = document.createElement('script');
				Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
				newScript.appendChild(document.createTextNode(origScript.innerHTML));
				origScript.parentNode?.replaceChild(newScript, origScript);
			});
			answerTemplateDiv.value?.querySelectorAll('script').forEach((origScript) => {
				const newScript = document.createElement('script');
				Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
				newScript.appendChild(document.createTextNode(origScript.innerHTML));
				origScript.parentNode?.replaceChild(newScript, origScript);
			});

			await nextTick();

			window.dispatchEvent(new Event('PGContentLoaded'));

			insertListeners();
		};

		const insertListeners = () => {
			const problemForm = problemTextDiv.value?.querySelector('form#problemMainForm') as HTMLFormElement;

			if (!problemForm) {
				// console.error('NO PROBLEM FORM FOUND');
				return;
			}

			let submitButton: HTMLInputElement | null = null;
			problemForm.querySelectorAll('input[type=submit]').forEach((button) => {
				button.addEventListener('click', () => submitButton = button as HTMLInputElement);
			});

			problemForm.addEventListener('submit', (e) => {
				e.preventDefault();
				if (!submitButton) {
					// console.error('No button was pressed...');
					return;
				}
				void loadProblem(new FormData(problemForm), problemForm.action ?? RENDER_URL, {
					[submitButton.name]: submitButton.value,
					// Again, we should not be overriding these on the frontend
					'problemSeed': '12345',
					'outputFormat': 'ww3'
				});
			});
		};

		watch(() => props.file, () => {
			_file.value = props.file;
			void loadProblem(new FormData(), RENDER_URL, {
				// We should not be overriding these on the frontend.
				'problemSeed': '12345',
				'sourceFilePath': _file.value,
				'outputFormat': 'ww3'
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
			insertListeners
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

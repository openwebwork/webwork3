<template>
	<q-card v-if="html" class="bg-grey-3">
		<q-card-section class="q-pa-sm">
			<div ref="renderDiv" v-html="html" class="pg-problem-container" />
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted, nextTick } from 'vue';
import { fetchProblem } from '../../APIRequests/renderer';
import { RENDER_URL } from '../../constants';
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
		submitAction: () => void
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
		const html = ref('');
		const _file = ref(props.file);
		const renderDiv = ref<HTMLElement>();

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

		const loadFresh = async () => {
			const overrides = {
				'problemSeed': '12345',
				'sourceFilePath': _file.value,
				'outputFormat': 'ww3'
			};
			await loadProblem(new FormData(), RENDER_URL, overrides);
		};

		const loadProblem = async (formData: FormData, url: string, overrides: {[k:string]: string}) => {
			if (!_file.value) {
				html.value = '';
				return;
			}

			const { renderedHTML, js, css } = await fetchProblem(formData, url, overrides);

			if (!renderedHTML) return;

			if (css?.length > 0) {
				await Promise.all(css.map(
					async (cssSource) => {
						await loadResource(cssSource).
							catch(() => { /* console.error(`Could not load ${cssSource}`) */ });
					}
				));
			}

			if (js?.length > 0) {
				await Promise.all(js.map(
					async (jsSource) => {
						await loadResource(jsSource).
							catch(() => { /* console.error(`Could not load ${jsSource}`) */ });
					}
				));
			}

			html.value = renderedHTML;
			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([renderDiv.value]));
			}

			await nextTick();

			// Execute any scripts in the pg output.
			renderDiv.value?.querySelectorAll('script').forEach((origScript) => {
				const newScript = document.createElement('script');
				Array.from(origScript.attributes).forEach((attr) => newScript.setAttribute(attr.name, attr.value));
				newScript.appendChild(document.createTextNode(origScript.innerHTML));
				origScript.parentNode?.replaceChild(newScript, origScript);
			});

			await nextTick();
			window.dispatchEvent(new Event('PGContentLoaded'));
			insertListeners();
		};

		function insertListeners() {
			const problemForm = renderDiv.value?.querySelector('form#problemMainForm') as HTMLFormElement;

			if (problemForm === undefined || problemForm === null) {
				// console.error('NO PROBLEM FORM FOUND');
				return;
			}

			problemForm.querySelectorAll('input[type=submit]').forEach(button => {
				button.addEventListener('click', () => {
					// keep ONLY the last button clicked
					problemForm.querySelectorAll('input[type=submit]').forEach(clean => {
						clean.classList.remove('btn-clicked');
					}); // clear all clicks
					button.classList.add('btn-clicked');
				});
			});

			problemForm.addEventListener('submit', (e: Event) => {
				e.preventDefault();
				const clickedButton = problemForm.querySelector('.btn-clicked') as HTMLButtonElement;
				void submitHandler(problemForm, clickedButton);
			});
		}

		async function submitHandler(form: HTMLFormElement, btn: HTMLButtonElement) {
			const submitUrl = form.getAttribute('action') ?? RENDER_URL;

			// submitAction is a global function from renderer - prepares for submit
			// e.g. updating hidden inputs from GeoGebra applet
			const submitAction = (window as Window).submitAction;
       		if(typeof submitAction === 'function') submitAction();

			if (btn) {
				const overrides = {
					[btn.name]: btn.value,
					// again, we should not be overriding these on the frontend
					'problemSeed': '1',
					'outputFormat': 'ww3'
				};
				await loadProblem(new FormData(form), submitUrl, overrides);
			} else {
				// console.error('No button was pressed...');
			}
		}

		watch(() => props.file, () => {
			_file.value = props.file;
			void loadFresh();
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
				['js/Knowls/knowl.js']
			] as Array<[string, string?]>).map(
				async (jsSource) => {
					await loadResource(...jsSource).
						catch(() => { /* console.error(`Could not load ${jsSource.src}`) */ });
				}
			));
		});

		return {
			html,
			renderDiv,
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

<template>
	<q-card v-if="html" class="bg-grey-3">
		<q-card-section class="q-pa-sm">
			<div ref="renderDiv" v-html="html" class="pg-problem-container" />
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, ref, watch, onMounted } from 'vue';
import type { RendererResponse } from '../../typings/renderer';
import axios from 'axios';
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

		const loadProblem = async () => {
			if (!_file.value) {
				html.value = '';
				return;
			}
			const formData = new FormData();
			formData.set('problemSeed', '12345');
			formData.set('sourceFilePath', _file.value);
			formData.set('outputFormat', 'ww3');

			let value, js, css;
			try {
				const response = await axios.post('/renderer/render-api', formData,
					{ headers: { 'Content-Type': 'multipart/form-data' } });

				const data = response.data as RendererResponse;

				value = data.renderedHTML;
				js = data.resources.js ?? [];
				css = data.resources.css ?? [];
			} catch(e) {
				return;
			}
			if (!value) return;

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

			html.value = value;
			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([renderDiv.value]));
			}
			/* eslint-enable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
		};

		watch(() => props.file, () => {
			_file.value = props.file;
			void loadProblem();
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
			renderDiv
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

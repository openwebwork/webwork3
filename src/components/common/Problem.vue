<template>
	<div ref="renderDiv" v-html="html" />
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, watch } from 'vue';
import { RendererResponse } from '../../typings/renderer';
import axios from 'axios';

import './mathjax-config';
import 'mathjax-full/es5/tex-chtml.js';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
interface Window {
	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	MathJax: any
}

export default defineComponent({
	name: 'Problem',
	props: {
		file: {
			type: String,
			default: ''
		}
	},
	setup(props){
		const html: Ref<string> = ref('');
		const _file: Ref<string> = ref(props.file);
		const renderDiv = ref<HTMLElement>();

		// modified from https://github.com/tserkov/vue-plugin-load-script
		async function loadScript(src: string) {
			console.log('loading scripts...', src);
			// eslint-disable-line no-param-reassign
			return new Promise(function (resolve, reject) {
				let shouldAppend = false;
				let el: HTMLScriptElement | HTMLLinkElement | null;
				create_el: if (/\.js(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
					el = document.querySelector('script[src="' + src + '"]');
					if (el && el.hasAttribute('data-loaded')) {
						resolve(el);
						return;
					} else if (el) {
						break create_el;
					}

					el = document.createElement('script');
					el.type = 'text/javascript';
					el.async = true;
					el.src = src;
					shouldAppend = true;
				} else if (/\.css(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
					el = document.querySelector('link[href="' + src + '"]');
					if (el && el.hasAttribute('data-loaded')) {
						resolve(el);
						return;
					} else if (el) {
						break create_el;
					}

					el = document.createElement('link');
					el.type = 'text/css';
					el.href = src;
					shouldAppend = true;
				} else {
					console.error(`Received invalid src: ${src}`);
					return;
				}

				el.addEventListener('error', reject);
				el.addEventListener('abort', reject);
				el.addEventListener('load', function loadScriptHandler() {
					el?.setAttribute('data-loaded', 'true');
					resolve(el);
				});

				if (shouldAppend) document.head.appendChild(el);
			});
		}

		async function loadProblem() {
			const formData = new FormData();
			formData.set('problemSeed', '12345');
			formData.set('sourceFilePath', _file.value);
			formData.set('outputFormat', 'test');

			let value, js, css;
			try {
				const response = await axios.post('/renderer/render-api', formData,
					{ headers: { 'Content-Type': 'multipart/form-data' } });

				const data = response.data as RendererResponse;
				console.log(data);

				value = data.renderedHTML;
				js = data.resources.js ?? [];
				css = data.resources.css ?? [];
			} catch(e) {
				return;
			}

			if (!value) return;
			html.value = value;
			// eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
			js.forEach((jsSource) => {
				loadScript(jsSource).
					then(() => console.log(`loaded ${jsSource}`)).
					catch(() => console.error(`Could not load ${jsSource}`));
			});

			css.forEach((jsSource) => {
				loadScript(jsSource).
					then(() => console.log(`loaded ${jsSource}`)).
					catch(() => console.error(`Could not load ${jsSource}`));
			});

			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([renderDiv.value]));
			}
		}

		watch(() => props.file, () => {
			_file.value = props.file;
			void loadProblem();
		});

		return {
			html,
			renderDiv
		};
	}
});
</script>

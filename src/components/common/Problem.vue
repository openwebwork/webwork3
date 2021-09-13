<template>
	<iframe
		v-resize="{ checkOrigin: false }"
		:srcdoc="html"
		width="100%"
		frameborder="0"
	></iframe>
</template>

<script lang="ts">
import { defineComponent, Ref, ref, watch } from 'vue';
import { iframeResizer } from 'iframe-resizer';
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
	directives: {
		resize: {
			mounted(el: HTMLElement, { value = {} }) {
				iframeResizer(value, el);
			},
			beforeUnmount(el) {
				// eslint-disable-next-line max-len
				// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
				el.iFrameResizer.removeListeners();
			}
		}
	},
	setup(props){
		const html: Ref<string> = ref('');
		const _file: Ref<string> = ref(props.file);
		const renderDiv = ref<HTMLElement>();

		async function loadProblem() {
			const formData = new FormData();
			formData.set('problemSeed', '1');
			formData.set('sourceFilePath', _file.value);
			formData.set('outputFormat', 'classic');

			let value;
			try {
				const response = await axios.post('/renderer/render-api', formData,
					{ headers: { 'Content-Type': 'multipart/form-data' } });

				value = (response.data as { renderedHTML: string }).renderedHTML;
			} catch(e) {
				return;
			}

			html.value = value;

			void Promise.resolve()
				.then(() => {
					/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
					window.MathJax.typesetPromise();
					/* eslint-enable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
				});
			// .catch();  // need to figure out a more robust way of handling an error like this.

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

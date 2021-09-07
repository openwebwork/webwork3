<template>
	<div ref="renderDiv" v-html="html" />
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, watch } from 'vue';
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

		async function loadProblem() {
			const formData = new FormData();
			formData.set('problemSeed', '1');
			formData.set('sourceFilePath', _file.value);
			formData.set('outputFormat', 'static');

			let value;
			try {
				const response = await axios.post('/renderer/render-api', formData,
					{ headers: { 'Content-Type': 'multipart/form-data' } });

				value = (response.data as { renderedHTML: string }).renderedHTML;
			} catch(e) {
				return;
			}

			if (!value) return;

			// Extract only the form element.
			const match = /<form(.*)>(.*)<\/form>/s.exec(value);
			if (match) html.value = match[0];

			/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
			if (window.MathJax && typeof window.MathJax.typesetPromise == 'function') {
				// eslint-disable-next-line @typescript-eslint/no-unsafe-return
				window.MathJax.startup.promise.then(() => window.MathJax.typesetPromise([renderDiv.value]));
			}
			/* eslint-enable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
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

<template>
	<div v-html="html" />
</template>
<script lang="ts">
import { defineComponent, Ref, ref, watch } from 'vue';
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

 		async function loadProblem() {
			const formData = new FormData();
			formData.set('problemSeed', '1');
			formData.set('sourceFilePath', _file.value);
			formData.set('outputFormat', 'static');

			const response = await axios.post('/renderer/render-api', formData,
				{ headers: { 'Content-Type': 'multipart/form-data' } });

			// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
			let value = response.data.renderedHTML as string;

			// extract only the form element.
			const match = /<form(.*)>(.*)<\/form>/s.exec(value);

			// replace the script tags with \( \) or \[ \]
			if (match) {
				html.value = match[0];
				// const m0 = match[0].replace(/<script type="math\/tex mode=display">(.+?)<\/script>/g, '\\[$1\\]');
				// html.value = m0.replace(/<script type="math\/tex">(.+?)<\/script>/g, '\\($1\\)');
			}
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
			html
		};
	}
});
</script>

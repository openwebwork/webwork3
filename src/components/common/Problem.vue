<template>
	<q-card>
		<q-card-section v-if="problem_type=='library'">
			<q-btn-group push>
				<q-btn size="sm" push icon="add" />
				<q-btn size="sm" push icon="edit" />
				<q-btn size="sm" push icon="shuffle" />
			</q-btn-group>
		</q-card-section>
		<q-card-section>
			<div ref="renderDiv" v-html="html" />
		</q-card-section>
	</q-card>
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
		},
		raw_source: {
			type: String,
			default: ''
		},
		type: {
			type: String,
			default: ''
		}
	},
	setup(props){
		const html: Ref<string> = ref('');
		const file_path: Ref<string> = ref(props.file);
		const problem_type: Ref<string> = ref(props.type);
		const renderDiv = ref<HTMLElement>();

		console.log(props);

		async function loadProblem() {
			const formData = new FormData();
			formData.set('problemSeed', '1');
			formData.set('sourceFilePath', file_path.value);
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

		if (file_path.value) {
			void loadProblem();
		}

		watch([file_path], () => {
			void loadProblem();
		});

		return {
			file_path,
			problem_type,
			html,
			renderDiv
		};
	}
});
</script>

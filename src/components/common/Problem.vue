<template>
	<iframe v-show="!isLoading"
		v-resize="{ checkOrigin: false }"
		:srcdoc="html"
		width="100%"
		frameborder="0"
		ref="problemIframe"
		@load="insertListeners()"
	></iframe>
	<div v-if="isLoading">Loading...</div>
</template>

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';
import { IFrameComponent, iframeResizer } from 'iframe-resizer';
import { ExtendedIFrameComponent } from '../../typings/iframe-resizer';
import { fetchProblem } from '../../APIRequests/renderer';
import { RENDER_URL } from '../../constants';
import axios from 'axios';

import './mathjax-config';
import 'mathjax-full/es5/tex-chtml.js';

declare global {
	interface Window {
		// eslint-disable-next-line @typescript-eslint/no-explicit-any
		MathJax: any
		submitAction: () => void
	}
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
			mounted(el: IFrameComponent, { value = {} }) {
				iframeResizer(value, el);
			},
			beforeUnmount(el: ExtendedIFrameComponent) {
				el.iFrameResizer.removeListeners();
			}
		}
	},
	setup(props){
		const html = ref('');
		const _file = ref(props.file);
		const problemIframe = ref<HTMLIFrameElement>();
		const isLoading = ref(true);

		async function loadProblem() {
			isLoading.value = true;
			html.value = '';

			// these overrides should be handled by passing requests
			// through the backend API, or by using JWE
			const overrides = {
				'problemSeed': '1',
				'sourceFilePath': _file.value,
				'outputFormat': 'classic'
			};
			const value = await fetchProblem(new FormData(), RENDER_URL, overrides);

			html.value = value;
			console.log('HTML updated...');

			return Promise.resolve()
				.then(() => {
					/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
					window.MathJax.typesetPromise();
					/* eslint-enable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
				});
			// .catch();  // need to figure out a more robust way of handling an error like this.
		}

		async function submitHandler(form: HTMLFormElement, btn: HTMLButtonElement) {
			const submitUrl = form.getAttribute('action') ?? '/renderer/render-api';
			// submitAction is a global function from renderer - prepares for submit
			const submitAction = (window as Window).submitAction;
       		if(typeof submitAction === 'function') submitAction();

			const formData = new FormData(form);
			let value = '';
			if (btn) {
				const overrides = {
					[btn.name]: btn.value,
					// again, we should not be overriding these on the frontend
					'problemSeed': '1',
					'outputFormat': 'classic'
				};

				value = await fetchProblem(formData, submitUrl, overrides);
			} else {
				console.error('No button was pressed...');
			}

			html.value = value;

			return Promise.resolve()
				.then(() => {
					/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
					window.MathJax.typesetPromise();
					/* eslint-enable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call */
				});
			// .catch();  // need to figure out a more robust way of handling an error like this.
		}

		function insertListeners() {
			const problemDoc = problemIframe?.value?.contentWindow?.document;
			if (!problemDoc) console.error('NO DOM AVAILABLE');
			const problemForm = problemDoc?.getElementById('problemMainForm') as HTMLFormElement;
			if (problemForm === undefined || problemForm === null) {
				console.error('NO PROBLEM FORM FOUND');
				return;
			}
			problemForm.addEventListener('submit', (e: Event) => {
				e.preventDefault();
				const clickedButton = problemForm.querySelector('.btn-clicked') as HTMLButtonElement;
				submitHandler(problemForm, clickedButton).catch((e)=>console.error(e));
			});
			isLoading.value = false;
		}

		watch(() => props.file, async () => {
			_file.value = props.file;
			await loadProblem();
		});

		return {
			html,
			isLoading,
			problemIframe,
			insertListeners
		};
	}
});
</script>

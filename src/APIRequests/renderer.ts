// This should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route.
import axios from 'axios';
import type { HTML, RendererResponse } from 'src/typings/renderer';

export async function fetchProblem(url: string, formData: FormData, overrides: { [key: string]: string }) {
	for (const key in overrides) {
		formData.set(key, overrides[key]);
	}

	let renderedHTML: HTML = {},
		js: Array<string> = [],
		css: Array<string> = [],
		renderError = '';

	try {
		const response = await axios.post(url, formData,
			{ headers: { 'Content-Type': 'multipart/form-data' } });

		const data = response.data as RendererResponse;

		renderedHTML = data.renderedHTML ?? {};
		js = data.resources.js ?? [];
		css = data.resources.css ?? [];
	} catch(e) {
		renderError = (e as Error).message;
	}

	return { renderedHTML, js, css, renderError };
}

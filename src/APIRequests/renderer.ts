// this should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route
import axios from 'axios';
import type { RendererResponse } from 'src/typings/renderer';

export async function fetchProblem(formData: FormData, url: string, overrides: {[k:string]: string}) {
	Object.keys(overrides).forEach((k)=>{
		formData.set(k, overrides[k]);
	});

	let renderedHTML = '';
	let js: Array<string> = [];
	let css: Array<string> = [];
	try {
		const response = await axios.post(url, formData,
			{ headers: { 'Content-Type': 'multipart/form-data' } });

		const data = response.data as RendererResponse;

		renderedHTML = data.renderedHTML;
		js = data.resources.js;
		css = data.resources.css;
	} catch(e) {
		renderedHTML = (e as Error).message;
	}

	return { renderedHTML, js, css };
}

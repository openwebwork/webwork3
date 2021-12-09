// This should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route.
import axios from 'axios';
import { logger } from 'boot/logger';
import type { HTML, RendererResponse } from 'src/typings/renderer';
import type { generic } from 'src/store/models';

export interface RendererParams {
	problemSeed?: number;
	outputFormat?: string;
	sourceFilePath?: string;
	problemSourceURL?: string; // OPLv3 endpoint
	problemSource?: string;    // raw pg source
	answerPrefix?: string;
	problemNumber?: number;
	psvn?: number;
	permissionLevel?: number; // we shouldn't set this on the frontend
	formURL?: string;
	baseURL?: string;
	language?: string;
	showHints?: boolean;
	showSolutions?: boolean;
	showPreviewButton?: boolean;
	showCheckAnswersButton?: boolean;
	showCorrectAnswersButton?: boolean;
	// renderer requests may have lots of other properties with unknown keys
	[key: string]: generic | undefined;
}

export async function fetchProblem(url: string, formData: FormData, overrides: RendererParams) {
	let key: keyof typeof overrides;
	for (key in overrides) {
		if (overrides[key] !== undefined) {
			logger.log('silly', `${key}: ${requestString(overrides[key])}`);
			formData.set(key, requestString(overrides[key]));
		} else {
			throw `Renderer request attempted with undefined value for property: ${key}`;
		}
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

function requestString(value: number|string|boolean|undefined): string {
	switch (typeof value) {
	case 'string': return value;
	case 'number': return `${value}`;
	case 'boolean': return (value) ? '1' : '0';
	default: throw 'key-value pair of unsupported type';
	}
}

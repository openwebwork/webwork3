// This should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route.
import axios from 'axios';
import { logger } from 'boot/logger';
import type { Dictionary, generic } from 'src/store/models';

export interface RendererParams extends Dictionary<generic> {
	problemSeed: number;
	outputFormat: string;
	//sourceFilePath?: string;
	//problemSourceURL?: string; // OPLv3 endpoint
	//problemSource?: string;    // raw pg source
	answerPrefix: string;
	//problemNumber?: number;
	//psvn?: number;
	permissionLevel: number; // we shouldn't set this on the frontend
	//formURL?: string;
	//baseURL?: string;
	language: string;
	//showHints?: boolean;
	//showSolutions?: boolean;
	//showPreviewButton?: boolean;
	//showCheckAnswersButton?: boolean;
	//showCorrectAnswersButton?: boolean;
}

export interface ExternalDeps {
	attributes: string;
	external: 0 | 1;
	file: string;
}

export interface Resources {
	css: Array<string>;
	js: Array<string>;
	regex: Array<string>;
	tags: Array<string>;
}

export interface Flags {
	ANSWER_ENTRY_ORDER: Array<string>;
	KEPT_EXTRA_ANSWERS: Array<string>;
	comment: string;
	hintExists: 0 | 1;
	extra_js_files: Array<ExternalDeps>;
	extra_css_files: Array<ExternalDeps>;
}

export interface SubmitButton {
	name: string;
	value: string;
}

export interface HTML {
	problemText?: string;
	answerTemplate?: string;
	submitButtons?: Array<SubmitButton>;
	scoreSummary?: string;
}

export interface RendererResponse {
	renderedHTML: HTML;
	flags: Flags;
	resources: Resources;
}

export async function fetchProblem(url: string, formData: FormData, overrides: RendererParams) {
	for (const key in overrides) {
		if (key in overrides && overrides[key] !== undefined) {
			logger.log('silly', `${key}: ${requestString(overrides[key])}`);
			formData.set(key, requestString(overrides[key]));
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
	} catch (e) {
		renderError = (e as Error).message;
	}

	return { renderedHTML, js, css, renderError };
}

function requestString(value: number | string | boolean | undefined): string {
	switch (typeof value) {
	case 'string': return value;
	case 'number': return `${value}`;
	case 'boolean': return (value) ? '1' : '0';
	default: throw 'key-value pair of unsupported type';
	}
}

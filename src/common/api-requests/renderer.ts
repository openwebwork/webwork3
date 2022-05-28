// This should more than likely be redirected at the backend rather
// than the renderer, unless we're going to go with the JWE route.
import axios from 'axios';
import { logger } from 'boot/logger';

import { ParseableRenderParams } from '../models/renderer';

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

export async function fetchProblem(url: string, formData: FormData, overrides: ParseableRenderParams) {
	for (const key in overrides) {
		if (key in overrides && overrides[key as keyof ParseableRenderParams] !== undefined) {
			logger.log('silly', `${key}: ${requestString(overrides[key as keyof ParseableRenderParams])}`);
			formData.set(key, requestString(overrides[key as keyof ParseableRenderParams]));
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

/**
 *
 * Loads CSS or JS files present in a problem.
 *
 */

export const loadResource = async (src: string, id?: string) => {
	return new Promise<void>((resolve, reject) => {
		let shouldAppend = false;
		let el: HTMLScriptElement | HTMLLinkElement | null;
		if (/\.js(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
			el = document.querySelector(`script[src="${src}"]`);
			if (!el) {
				el = document.createElement('script');
				if (id) el.id = id;
				el.async = false;
				el.src = src;
				shouldAppend = true;
			}
		} else if (/\.css(?:\??[0-9a-zA-Z=]*)$/.exec(src)) {
			el = document.querySelector(`link[href="${src}"]`);
			if (!el) {
				el = document.createElement('link');
				el.rel = 'stylesheet';
				el.href = src;
				shouldAppend = true;
			}
		} else {
			reject();
			return;
		}

		if (el.dataset.loaded) {
			resolve();
			return;
		}

		el.addEventListener('error', reject);
		el.addEventListener('abort', reject);
		el.addEventListener('load', () => {
			if (el) el.dataset.loaded = 'true';
			resolve();
		});

		if (shouldAppend) document.head.appendChild(el);
	});
};

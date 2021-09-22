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
}

export interface RendererResponse {
    renderedHTML: HTML | string;
    flags: Flags;
    resources: Resources;
}

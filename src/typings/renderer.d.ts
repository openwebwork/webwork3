interface ExternalDeps {
    attributes: string;
    external: 0 | 1;
    file: string;
}

interface Resources {
    css: Array<string>;
    js: Array<string>;
    regex: Array<string>;
    tags: Array<string>;
}

interface Flags {
    ANSWER_ENTRY_ORDER: Array<string>;
    KEPT_EXTRA_ANSWERS: Array<string>;
    comment: string;
    hintExists: 0 | 1;
    extra_js_files: Array<ExternalDeps>;
    extra_css_files: Array<ExternalDeps>;
}

export interface RendererResponse {
    renderedHTML: string;
    flags: Flags;
    resources: Resources;
}

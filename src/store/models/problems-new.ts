import { Model, ModelParams, Dictionary, generic } from './model-new';
import { RenderParams, RenderParamsFields } from './renderer-new';

// This is associated with problems from the Library (OPLv3 or local)

export interface ParseableLibraryParams extends Partial<Dictionary<generic>> {
	library_id?: string | number;
	file_path?: string;
	problem_pool_id?: string | number;
}

export interface ParseableLibraryProblem {
	library_params?: ParseableLibraryParams;
	render_params?: RenderParamsFields;
}

class LibraryParams extends ModelParams([], ['library_id', 'problem_pool_id'],
	['file_path'], {
		library_id: { field_type: 'non_neg_int' },
		problem_pool_id: { field_type: 'non_neg_int' },
		file_path: { field_type: 'string' },
	}) {}

export class Problem extends Model {
	private _render_params = new RenderParams();
	protected _problem_type = '';

	get render_params() { return this._render_params; }

	get problem_type() { return this._problem_type; }

	get all_field_names() { return ['render_params']; }

	get param_fields() { return ['render_params']; }

	constructor(params: { render_params?: Partial<RenderParamsFields> } = {}) {
		super();
		if (params.render_params) {
			this.setRenderParams(params.render_params);
		}
	}

	setRenderParams(params: Partial<RenderParamsFields>) {
		this._render_params.set(params);
	}

	clone(): Problem {
		throw 'you must override the clone method in the subclass.';
	}

	path(): string {
		throw 'you must override the path method in the subclass.';
		return '';
	}

	requestParams() {
		return this.render_params.toObject() as RenderParamsFields;
	}
}
export class LibraryProblem extends Problem {
	private _library_params = new LibraryParams();

	get library_params() { return this._library_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = 'LIBRARY';
		if (params.library_params) {
			this.setLibraryParams(params.library_params);
		}
	}

	get all_field_names() {
		return [ ...super.all_field_names, ...['library_params']];
	}

	get param_fields() { return [...super.param_fields, ...['library_params'] ]; }

	setLibraryParams(params: ParseableLibraryParams) {
		this._library_params.set(params);
	}

	clone(): LibraryProblem {
		return new LibraryProblem(this.toObject() as unknown as ParseableLibraryProblem);
	}

	path(): string {
		return this.library_params.file_path ?? '';
	}

	requestParams(): RenderParamsFields {
		const p = super.requestParams();
		p.sourceFilePath = this.library_params.file_path ?? '';
		return p;
	}
}

// import { AddRendering } from './renderer-new';

// export const LibraryProblem = AddRendering(LibProblem);

import { parseNonNegInt } from 'src/store/models';
import { Model, ModelParams, Dictionary, generic } from '.';
import { RenderParams, RenderParamsFields } from './renderer';

/**
 * This is a super class of all Problems.
 */
export class Problem extends Model {
	private _render_params = new RenderParams();
	protected _problem_type = '';

	private _problem_number = 0;

	get render_params() { return this._render_params; }

	get problem_type() { return this._problem_type; }

	get all_field_names() { return ['render_params']; }

	get param_fields() { return ['render_params']; }

	get problem_number() { return this._problem_number; }
	set problem_number(value: string | number) {
		this._problem_number = parseNonNegInt(value);
	}

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

// This is associated with problems from the Library (OPLv3 or local)

export interface ParseableLibraryParams extends Partial<Dictionary<generic>> {
	library_id?: string | number;
	file_path?: string;
	problem_pool_id?: string | number;
}

export interface ParseableLibraryProblem {
	library_params?: ParseableLibraryParams;
	render_params?: RenderParamsFields;
	problem_number?: number;
}

class LibraryParams extends ModelParams([], ['library_id', 'problem_pool_id'],
	['file_path'], {
		library_id: { field_type: 'non_neg_int' },
		problem_pool_id: { field_type: 'non_neg_int' },
		file_path: { field_type: 'string' },
	}) {}
export class LibraryProblem extends Problem {
	private _library_params = new LibraryParams();

	get library_params() { return this._library_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = 'LIBRARY';
		if (params.library_params) {
			this.setLibraryParams(params.library_params);
		}
		// For these problems, all buttons are shown by default.
		this.setRenderParams({
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		});
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

export interface ParseableSetProblemParams extends Partial<Dictionary<generic>> {
	library_id?: string | number;
	file_path?: string;
	problem_pool_id?: string | number;
}

export interface ParseableSetProblem {
	library_params?: ParseableSetProblemParams;
	render_params?: RenderParamsFields;
	problem_number?: number;
}

/**
 * The class SetProblem is used for problems in Problem Sets (Homework, Quiz, Review)
 */
export class SetProblem extends Problem {
	private _library_params = new LibraryParams();

	get library_params() { return this._library_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = 'SET';
		if (!params.library_params) params.library_params = {};
		// For these problems, all buttons are shown by default.
		this.setLibraryParams(Object.assign({
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		}, params.library_params));
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

type ParseableProblem = ParseableLibraryProblem | ParseableSetProblem;

export function parseProblem(problem: ParseableProblem, type: string) {
	switch (type) {
	case 'Library': return new LibraryProblem(problem);
	case 'Set': return new SetProblem(problem);
	}
}

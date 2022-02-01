import { parseNonNegDecimal, parseNonNegInt } from './parsers';
import { Model, Dictionary, generic } from '.';
import { RenderParams, ParseableRenderParams } from './renderer';

/**
 * This is a super class of all Problems.
 */
export class Problem extends Model {
	private _render_params = new RenderParams();
	protected _problem_type = '';

	private _problem_number = 0;

	get render_params() { return this._render_params; }

	get problem_type() { return this._problem_type; }

	get all_field_names() { return ['problem_number', 'problem_type', 'render_params']; }

	get param_fields() { return ['render_params']; }

	get problem_number(): number { return this._problem_number; }
	set problem_number(value: string | number) {
		this._problem_number = parseNonNegInt(value);
	}

	constructor(params: { render_params?: ParseableRenderParams } = {}) {
		super();
		if (params.render_params) {
			this.setRenderParams(params.render_params);
		}
	}

	setRenderParams(params: ParseableRenderParams) {
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
		return this.render_params.toObject() as ParseableRenderParams;
	}
}

// This is associated with problems from the Library (OPLv3 or local)

// Currently we just have a problem associated with the file_path (or
// fileSourcePath), but the following makes it more flexible to
// pull from the library with an id or from

export interface ParseableLocationParams extends Partial<Dictionary<generic>> {
	library_id?: string | number;
	file_path?: string;
	problem_pool_id?: string | number;
}

export interface ParseableLibraryProblem {
	location_params?: ParseableLocationParams;
	render_params?: ParseableRenderParams;
	problem_number?: number;
}

class ProblemLocationParams extends Model {
	private _library_id = 0;
	private _file_path = '';
	private _problem_pool_id = 0;

	get all_field_names(): string[] {
		return ['library_id', 'file_path', 'problem_pool_id'];
	}
	get param_fields(): string[] {
		return [];
	}

	constructor(params: ParseableLocationParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableLocationParams) {
		if (params.library_id != undefined) this.library_id = params.library_id;
		if (params.file_path != undefined) this.file_path = params.file_path;
		if (params.problem_pool_id != undefined) this.problem_pool_id = params.problem_pool_id;

	}

	public get library_id() : number { return this._library_id; }
	public set library_id(val: string | number) { this._library_id = parseNonNegInt(val);}

	public get file_path() : string { return this._file_path;}
	public set file_path(value: string) { this._file_path = value;}

	public get problem_pool_id() : number { return this._problem_pool_id; }
	public set problem_pool_id(val: string | number) { this._problem_pool_id = parseNonNegInt(val);}

}

/**
 * The class LibraryProblem is used to handle problems in the LibraryBrowser and
 * other places where Library Problems are used.
 */

export class LibraryProblem extends Problem {
	private _location_params = new ProblemLocationParams();

	get location_params() { return this._location_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = 'LIBRARY';
		if (params.location_params) {
			this.setLocationParams(params.location_params);
		}
		// For these problems, all buttons are shown by default.
		this.setRenderParams({
			showSolutions: true,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		});
	}

	get all_field_names() {
		return [ ...super.all_field_names, ...['location_params']];
	}

	get param_fields() { return [...super.param_fields, ...['library_params'] ]; }

	setLocationParams(params: ParseableLocationParams) {
		this._location_params.set(params);
	}

	clone(): LibraryProblem {
		return new LibraryProblem(this.toObject() as unknown as ParseableLibraryProblem);
	}

	path(): string {
		return this.location_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		// Currently the file path must be sent for Render Params.
		// In the future, we need to be able to send other params.
		p.sourceFilePath = this.location_params.file_path ?? '';
		return p;
	}
}

export interface ParseableSetProblemParams {
	weight?: number | string;
	library_id?: number | string;
	file_path?: string;
	problem_pool_id?: number | string;
}

class SetProblemParams extends Model {
	private _weight = 1;
	private _library_id = 0;
	private _file_path = '';
	private _problem_pool_id = 0;

	get all_field_names(): string[] {
		return ['weight', 'library_id', 'file_path', 'problem_pool_id'];
	}

	get param_fields() { return [];}

	constructor(params: ParseableSetProblemParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableSetProblemParams) {
		if (params.library_id != undefined) this.library_id = params.library_id;
		if (params.file_path != undefined) this.file_path = params.file_path;
		if (params.problem_pool_id != undefined) this.problem_pool_id = params.problem_pool_id;

	}

	public get weight(): number { return this._weight; }
	public set weight(value: number | string) { this._weight = parseNonNegDecimal(value);}

	public get library_id() : number { return this._library_id; }
	public set library_id(val: string | number) { this._library_id = parseNonNegInt(val);}

	public get file_path() : string { return this._file_path;}
	public set file_path(value: string) { this._file_path = value;}

	public get problem_pool_id() : number { return this._problem_pool_id; }
	public set problem_pool_id(val: string | number) { this._problem_pool_id = parseNonNegInt(val);}

}

export interface ParseableSetProblem {
	render_params?: RenderParams;
	problem_params?: SetProblemParams;
	problem_number?: number | string ;
	problem_id?: number | string;
	set_id?: number | string;
}

/**
 * The class SetProblem is used for problems in Problem Sets (Homework, Quiz, Review)
 */
export class SetProblem extends Problem {
	private _problem_params = new SetProblemParams();
	private _problem_id = 0;
	private _set_id = 0;

	constructor(params: ParseableSetProblem = {}) {
		super(params);
		this.set(params);
		this._problem_type = 'SET';
		if (params.problem_params) this.problem_params.set(params.problem_params);
		// For these problems, all buttons are shown by default.
		this.setRenderParams({
			showSolutions: true,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		});
	}

	set(params: ParseableSetProblem) {
		if (params.problem_id != undefined) this.problem_id = params.problem_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.problem_number != undefined) this.problem_number = params.problem_number;
	}

	get problem_params() { return this._problem_params; }

	get all_field_names() {
		return ['problem_id', 'problem_number', 'set_id', 'problem_params'];
	}

	get param_fields() { return ['problem_params' ]; }

	public get problem_id() : number { return this._problem_id; }
	public set problem_id(val: string | number) { this._problem_id = parseNonNegInt(val);}

	public get set_id() : number { return this._set_id; }
	public set set_id(val: string | number) { this._set_id = parseNonNegInt(val);}

	clone(): SetProblem {
		return new SetProblem(this.toObject() as unknown as ParseableSetProblem);
	}

	path(): string {
		return this.problem_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.problem_params.file_path ?? '';
		return p;
	}
}

export type ParseableProblem = ParseableLibraryProblem | ParseableSetProblem;

export function parseProblem(problem: ParseableProblem, type: 'Library' | 'Set') {
	switch (type) {
	case 'Library': return new LibraryProblem(problem as ParseableLibraryProblem);
	case 'Set': return new SetProblem(problem as ParseableSetProblem);
	}
}

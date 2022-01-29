import { parseNonNegInt } from 'src/store/models';
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

	get all_field_names() { return ['render_params']; }

	get param_fields() { return ['render_params']; }

	get problem_number() { return this._problem_number; }
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

export interface ParseableProblemLocation extends Partial<Dictionary<generic>> {
library_id?: string | number;
file_path?: string;
problem_pool_id?: string | number;
}

export interface ParseableLibraryProblem {
	problem_location_params?: ParseableProblemLocation;
	render_params?: ParseableRenderParams;
	problem_number?: number;
}

class ProblemLocationParams extends Model {
	private _library_id = 0;
	private _file_path = '';
	private _problem_pool_id = 0;

	constructor(params: ParseableProblemLocation = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableProblemLocation) {
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
	private _problem_location_params = new ProblemLocationParams();

	get problem_location_params() { return this._problem_location_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = 'LIBRARY';
		if (params.problem_location_params) {
			this.setProbLocParams(params.problem_location_params);
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
		return [ ...super.all_field_names, ...['library_params']];
	}

	get param_fields() { return [...super.param_fields, ...['library_params'] ]; }

	setProbLocParams(params: ParseableProblemLocation) {
		this._problem_location_params.set(params);
	}

	clone(): LibraryProblem {
		return new LibraryProblem(this.toObject() as unknown as ParseableLibraryProblem);
	}

	path(): string {
		return this.problem_location_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		// Currently the file path must be sent for Render Params.
		// In the future, we need to be able to send other params.
		p.sourceFilePath = this.problem_location_params.file_path ?? '';
		return p;
	}
}

export interface ParseableSetProblemParams extends Partial<Dictionary<generic>> {
	library_id?: string | number;
	file_path?: string;
	problem_pool_id?: string | number;
}

export interface ParseableSetProblem {
	problem_location_params?: ParseableProblemLocation;
	render_params?: ParseableRenderParams;
	problem_number?: number;
}

/**
 * The class SetProblem is used for problems in Problem Sets (Homework, Quiz, Review)
 */
export class SetProblem extends Problem {
	private _problem_location_params = new ProblemLocationParams();

	get library_params() { return this._problem_location_params; }

	constructor(params: ParseableSetProblem = {}) {
		super(params);
		this._problem_type = 'SET';
		if (params.problem_location_params) this.setProbLocParams(params.problem_location_params);
		// For these problems, all buttons are shown by default.
		this.setRenderParams({
			showSolutions: true,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		});
	}

	get all_field_names() {
		return [ ...super.all_field_names, ...['library_params']];
	}

	get param_fields() { return [...super.param_fields, ...['library_params'] ]; }

	setProbLocParams(params: ParseableProblemLocation) {
		this._problem_location_params.set(params);
	}

	clone(): SetProblem {
		return new SetProblem(this.toObject() as unknown as ParseableSetProblem);
	}

	path(): string {
		return this.library_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.library_params.file_path ?? '';
		return p;
	}
}

type ParseableProblem = ParseableLibraryProblem | ParseableSetProblem;

export function parseProblem(problem: ParseableProblem, type: 'Library' | 'Set') {
	switch (type) {
	case 'Library': return new LibraryProblem(problem);
	case 'Set': return new SetProblem(problem);
	}
}

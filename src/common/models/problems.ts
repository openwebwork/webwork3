import { parseNonNegDecimal, parseNonNegInt, parseUsername } from './parsers';
import { Model, Dictionary, generic } from '.';
import { RenderParams, ParseableRenderParams } from './renderer';

export enum ProblemType {
	LIBRARY = 'LIBRARY',
	SET = 'SET',
	USER = 'USER',
	MERGED_USER = 'MERGED_USER',
	UNKNOWN = 'UNKNOWN'
}

/**
 * This is a super class of all Problems.
 */
export class Problem extends Model {
	private _render_params = new RenderParams();
	protected _problem_type = ProblemType.UNKNOWN;

	get render_params() { return this._render_params; }
	get problem_type() { return this._problem_type; }

	get all_field_names() { return ['render_params']; }

	get param_fields() { return ['render_params']; }

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

/**
 * ParseableLocationParams stores information about a library problem.
 */
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
	private _problem_number = 0; // used for display in library browser.
	get location_params() { return this._location_params; }

	constructor(params: ParseableLibraryProblem = {}) {
		super(params);
		this._problem_type = ProblemType.LIBRARY;
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

	static ALL_FIELDS = ['location_params', 'render_params'];

	get all_field_names() {
		return [ ...super.all_field_names, ...['location_params']];
	}

	get problem_number(): number { return this._problem_number; }
	set problem_number(value: string | number) { this._problem_number = parseNonNegInt(value); }

	get param_fields() { return [...super.param_fields, ...['location_params'] ]; }

	// Maybe get rid of this and just assign location_params directly.

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

// This next set of interfaces and classes are related to SetProblems

export interface ParseableSetProblemParams {
	weight?: number | string;
	library_id?: number | string;
	file_path?: string;
	problem_pool_id?: number | string;
}

/**
 * SetProblemParams stores the parameters for a SetProblem including information
 * about the location of the problem and the weight of the problem.
 */

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
		if (params.weight != undefined) this.weight = params.weight;
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
	render_params?: ParseableRenderParams;
	problem_params?: ParseableSetProblemParams;
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
	private _problem_number = 0;

	constructor(params: ParseableSetProblem = {}) {
		super(params);
		this.set(params);
		this._problem_type = ProblemType.SET;
		if (params.problem_params) this.problem_params.set(params.problem_params);
		// For these problems, all buttons are shown by default.
		this.setRenderParams({
			showSolutions: true,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: true
		});
	}

	static ALL_FIELDS = ['problem_id', 'problem_number', 'set_id',
		'problem_params', 'render_params'];

	set(params: ParseableSetProblem) {
		if (params.problem_id != undefined) this.problem_id = params.problem_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.problem_number != undefined) this.problem_number = params.problem_number;
	}

	get problem_params() { return this._problem_params; }

	get all_field_names() {
		return [ ...super.all_field_names, ...['problem_id', 'set_id', 'problem_number', 'problem_params']];
	}

	get param_fields() { return [...super.param_fields, ...['problem_params'] ]; }

	public get problem_id() : number { return this._problem_id; }
	public set problem_id(val: string | number) { this._problem_id = parseNonNegInt(val);}

	public get set_id() : number { return this._set_id; }
	public set set_id(val: string | number) { this._set_id = parseNonNegInt(val);}

	get problem_number(): number { return this._problem_number; }
	set problem_number(value: string | number) { this._problem_number = parseNonNegInt(value); }

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
interface ParseableUserProblemParams {
	weight?: number | string;
	library_id?: number | string;
	file_path?: string;
	problem_pool_id?: number | string;
}

/**
 * This class is the problem params for a UserProblem for use in overriding any
 * SetProblem parameters.   This includes informatio about the problem location and
 * the weight.
 */

class UserProblemParams extends Model {
	private _weight?: number;
	private _library_id?: number;
	private _file_path?: string;
	private _problem_pool_id?: number;

	get all_field_names(): string[] {
		return ['weight', 'library_id', 'file_path', 'problem_pool_id'];
	}

	get param_fields() { return [];}

	constructor(params: ParseableUserProblemParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableUserProblemParams) {
		if (params.weight != undefined) this.weight = params.weight;
		if (params.library_id != undefined) this.library_id = params.library_id;
		if (params.file_path != undefined) this.file_path = params.file_path;
		if (params.problem_pool_id != undefined) this.problem_pool_id = params.problem_pool_id;

	}

	public get weight(): number | undefined { return this._weight; }
	public set weight(val: number | string | undefined) {
		if (val != undefined) this._weight = parseNonNegDecimal(val);
	}

	public get library_id() : number | undefined { return this._library_id; }
	public set library_id(val: string | number | undefined) {
		if (val != undefined) this._library_id = parseNonNegInt(val);
	}

	public get file_path() : string | undefined { return this._file_path;}
	public set file_path(val: string | undefined) {
		if (val != undefined) this._file_path = val;
	}

	public get problem_pool_id() : number | undefined { return this._problem_pool_id; }
	public set problem_pool_id(val: string | number | undefined) {
		if (val != undefined) this._problem_pool_id = parseNonNegInt(val);
	}

}

export interface ParseableUserProblem {
	render_params?: RenderParams;
	problem_params?: UserProblemParams;
	problem_id?: number | string;
	user_problem_id?: number | string;
	user_id?: number | string;
	seed?: number | string;
	status?: number | string;
	problem_version?: number | string;
}

/**
 * The class UserProblem is used for problems assigned to Users
 */
export class UserProblem extends Problem {
	private _problem_params = new UserProblemParams();
	private _user_problem_id = 0;
	private _problem_id = 0;
	private _user_id = 0;
	private _seed = 0;
	private _status = 0;
	private _problem_version = 1;

	constructor(params: ParseableUserProblem = {}) {
		super(params);
		this.set(params);
		this._problem_type = ProblemType.USER;
		if (params.problem_params) this.problem_params.set(params.problem_params);
		// For these problems, by default show preview and check answers.
		this.setRenderParams({
			showSolutions: false,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: false
		});
	}

	set(params: ParseableUserProblem) {
		if (params.problem_id != undefined) this.problem_id = params.problem_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.user_problem_id != undefined) this.user_problem_id = params.user_problem_id;
		if (params.seed != undefined) this.seed = params.seed;
		if (params.status != undefined) this.status = params.status;
		if (params.problem_version != undefined) this.problem_version = params.problem_version;
	}

	static ALL_FIELDS = ['user_problem_id', 'problem_id', 'user_id', 'seed', 'status',
		'problem_version', 'render_params', 'problem_params'];

	get problem_params() { return this._problem_params; }

	get all_field_names() {
		return UserProblem.ALL_FIELDS;
	}

	get param_fields() { return ['problem_params', 'render_params']; }

	public get problem_id() : number { return this._problem_id; }
	public set problem_id(val: string | number) { this._problem_id = parseNonNegInt(val);}

	public get user_problem_id() : number { return this._user_problem_id; }
	public set user_problem_id(val: string | number) { this._user_problem_id = parseNonNegInt(val);}

	public get user_id() : number { return this._user_id; }
	public set user_id(val: string | number) { this._user_id = parseNonNegInt(val);}

	public get seed() : number { return this._seed; }
	public set seed(val: string | number) { this._seed = parseNonNegInt(val);}

	public get status() : number { return this._status; }
	public set status(val: string | number) { this._status = parseNonNegDecimal(val);}

	public get problem_version() : number { return this._problem_version; }
	public set problem_version(val: string | number) { this._problem_version = parseNonNegInt(val);}

	public clone() {
		return new UserProblem(this.toObject() as unknown as ParseableUserProblem);
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

// This next section is related to MergedUserProblems

export interface ParseableMergedUserProblem {
	render_params?: RenderParams;
	user_problem_params?: UserProblemParams;
	set_problem_params?: SetProblemParams;
	problem_id?: number | string;
	user_problem_id?: number | string;
	user_id?: number | string;
	set_id?: number | string;
	seed?: number | string;
	status?: number | string;
	problem_version?: number | string;
	problem_number?: number | string;
	username?: string;
	set_name?: string;
}

/**
 * The class MergedUserProblem is used for merging User and set problems
 */
export class MergedUserProblem extends Problem {
	private _set_problem_params = new SetProblemParams();
	private _user_problem_params = new UserProblemParams();
	private _user_problem_id = 0;
	private _problem_id = 0;
	private _user_id = 0;
	private _set_id = 0;
	private _seed = 0;
	private _status = 0;
	private _problem_version = 1;
	private _problem_number = 0;
	private _username = '';
	private _set_name = '';

	constructor(params: ParseableMergedUserProblem = {}) {
		super(params);
		this.set(params);
		this._problem_type = ProblemType.MERGED_USER;
		if (params.set_problem_params) this.set_problem_params.set(params.set_problem_params);
		if (params.user_problem_params) this.user_problem_params.set(params.user_problem_params);
		// For merged user problems, preview and check answer are on my default.
		this.setRenderParams({
			showSolutions: false,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: false
		});
	}

	set(params: ParseableMergedUserProblem) {
		if (params.problem_id != undefined) this.problem_id = params.problem_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.user_problem_id != undefined) this.user_problem_id = params.user_problem_id;
		if (params.seed != undefined) this.seed = params.seed;
		if (params.status != undefined) this.status = params.status;
		if (params.problem_version != undefined) this.problem_version = params.problem_version;
		if (params.problem_number != undefined) this.problem_number = params.problem_number;
		if (params.username != undefined) this.username = params.username;
		if (params.set_name != undefined) this.set_name = params.set_name;
	}

	// Need to determine a good way to do overrides. That is if
	// user_problem_params.file_path is defined use it if not use set_problem_params.file_path

	get set_problem_params() { return this._set_problem_params; }
	get user_problem_params() { return this._user_problem_params; }

	static ALL_FIELDS = ['user_problem_id', 'problem_id', 'user_id', 'seed', 'status',
		'problem_number', 'username', 'set_name', 'problem_version', 'set_problem_params',
		'user_problem_params', 'render_params'];

	get all_field_names() {
		return MergedUserProblem.ALL_FIELDS;
	}

	get param_fields() { return ['set_problem_params', 'user_problem_params', 'render_params']; }

	public get problem_id() : number { return this._problem_id; }
	public set problem_id(val: string | number) { this._problem_id = parseNonNegInt(val);}

	public get user_problem_id() : number { return this._user_problem_id; }
	public set user_problem_id(val: string | number) { this._user_problem_id = parseNonNegInt(val);}

	public get user_id() : number { return this._user_id; }
	public set user_id(val: string | number) { this._user_id = parseNonNegInt(val);}

	public get set_id() : number { return this._set_id; }
	public set set_id(val: string | number) { this._set_id = parseNonNegInt(val);}

	public get seed() : number { return this._seed; }
	public set seed(val: string | number) { this._seed = parseNonNegInt(val);}

	public get status() : number { return this._status; }
	public set status(val: string | number) { this._status = parseNonNegDecimal(val);}

	public get problem_version() : number { return this._problem_version; }
	public set problem_version(val: string | number) { this._problem_version = parseNonNegInt(val);}

	public get problem_number() : number { return this._problem_number; }
	public set problem_number(val: string | number) { this._problem_number = parseNonNegInt(val);}

	public get username() : string { return this._username; }
	public set username(val: string) { this._username = parseUsername(val);}

	public get set_name() : string { return this._set_name; }
	public set set_name(val: string) { this._set_name = val;}

	public clone() {
		return new MergedUserProblem(this.toObject() as unknown as ParseableMergedUserProblem);
	}

	path(): string {
		return this.user_problem_params.file_path ?? this.set_problem_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.path();
		return p;
	}
}

export type ParseableProblem = ParseableLibraryProblem | ParseableSetProblem | ParseableUserProblem;

export function parseProblem(problem: ParseableProblem, type: 'Library' | 'Set' | 'User') {
	switch (type) {
	case 'Library': return new LibraryProblem(problem as ParseableLibraryProblem);
	case 'Set': return new SetProblem(problem as ParseableSetProblem);
	case 'User': return new UserProblem(problem as ParseableUserProblem);
	}
}

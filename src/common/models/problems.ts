// Definition of Problems (SetProblems, LibraryProblems and UserProblems)

import { isNonNegDecimal, isNonNegInt, isValidUsername, MergeError } from './parsers';
import { Model, Dictionary, generic } from '.';
import { RenderParams, ParseableRenderParams } from './renderer';
import { UserSet } from './user_sets';

export enum ProblemType {
	LIBRARY = 'LIBRARY',
	SET = 'SET',
	DB_USER = 'DB_USER',
	USER = 'USER',
	UNKNOWN = 'UNKNOWN'
}

/**
 * This is a super class of all Problems (Library, Set and User varieties).
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
	library_id?: number;
	file_path?: string;
	problem_pool_id?: number;
}

export interface ParseableLibraryProblem {
	location_params?: ParseableLocationParams;
	render_params?: ParseableRenderParams;
	problem_number?: number;
}

class ProblemLocationParams extends Model {
	private _library_id?: number;
	private _file_path?: string;
	private _problem_pool_id?: number;

	get all_field_names(): string[] { return ['library_id', 'file_path', 'problem_pool_id']; }
	get param_fields(): string[] { return []; }

	constructor(params: ParseableLocationParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableLocationParams) {
		this.library_id = params.library_id;
		this.file_path = params.file_path;
		this.problem_pool_id = params.problem_pool_id;
	}

	public get library_id() : number | undefined { return this._library_id; }
	public set library_id(val: number | undefined) {
		if (val != undefined) this._library_id = val;
	}

	public get file_path() : string | undefined { return this._file_path;}
	public set file_path(value: string | undefined) {
		if (value != undefined) this._file_path = value;}

	public get problem_pool_id() : number | undefined { return this._problem_pool_id; }
	public set problem_pool_id(val: number | undefined) {
		if (val != undefined) this._problem_pool_id = val;
	}

	clone(): ProblemLocationParams {
		return new ProblemLocationParams(this.toObject() as ParseableLocationParams);
	}

	// Ensure that the _id fields are non-negative integers and that at least one
	// of the three fields are defined.
	isValid() {
		if (this.library_id != undefined && !isNonNegInt(this.library_id)) return false;
		if (this.problem_pool_id != undefined && !isNonNegInt(this.problem_pool_id)) return false;
		return this.problem_pool_id != undefined || this.library_id != undefined || this.file_path != undefined;
	}
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
			this.location_params.set(params.location_params);
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
	set problem_number(value: number) { this._problem_number = value; }

	get param_fields() { return [...super.param_fields, ...['location_params'] ]; }

	clone(): LibraryProblem {
		return new LibraryProblem(this.toObject() as unknown as ParseableLibraryProblem);
	}

	path(): string {
		return this.location_params.file_path ?? '';
	}

	isValid() {
		return isNonNegInt(this.problem_number) && this.location_params.isValid();
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
	weight?: number;
	library_id?: number;
	file_path?: string;
	problem_pool_id?: number;
}

/**
 * SetProblemParams stores the parameters for a SetProblem including information
 * about the location of the problem and the weight of the problem.
 */
export class SetProblemParams extends Model {
	private _weight = 1;
	private _library_id?: number;
	private _file_path?: string;
	private _problem_pool_id?: number;

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
		this.library_id = params.library_id;
		this.file_path = params.file_path;
		this.problem_pool_id = params.problem_pool_id;
	}

	public get weight(): number { return this._weight; }
	public set weight(value: number) { this._weight = value; }

	public get library_id() : number | undefined { return this._library_id; }
	public set library_id(val: number | undefined) {
		if (val != undefined) this._library_id = val;
	}

	public get file_path() : string | undefined { return this._file_path;}
	public set file_path(value: string | undefined) {
		if (value) this._file_path = value;
	}

	public get problem_pool_id() : number | undefined { return this._problem_pool_id; }
	public set problem_pool_id(val: number | undefined) {
		if (val != undefined) this._problem_pool_id = val;
	}

	// Ensure that weight is not negative, the _id fields are non-negative integers and
	// that at least one of the three location fields is defined.
	isValid() {
		if (!isNonNegDecimal(this.weight)) return false;
		if (this.library_id != undefined && !isNonNegInt(this.library_id)) return false;
		if (this.problem_pool_id != undefined && !isNonNegInt(this.problem_pool_id)) return false;
		return Object.keys(this.toObject(['problem_pool_id', 'library_id', 'file_path'])).length > 0;
	}
}

export interface ParseableSetProblem {
	render_params?: ParseableRenderParams;
	problem_params?: ParseableSetProblemParams;
	problem_number?: number;
	set_problem_id?: number;
	set_id?: number;
}

/**
 * The class SetProblem is used for problems in Problem Sets (Homework, Quiz, Review)
 */

export class SetProblem extends Problem {
	private _problem_params = new SetProblemParams();
	private _set_problem_id = 0;
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
			showCorrectAnswersButton: true,
			answerPrefix: `${this.problem_type}${this.problem_number}_`,
		});
	}

	static ALL_FIELDS = ['set_problem_id', 'problem_number', 'set_id',
		'problem_params', 'render_params'];

	set(params: ParseableSetProblem) {
		if (params.set_problem_id != undefined) this.set_problem_id = params.set_problem_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.problem_number != undefined) this.problem_number = params.problem_number;
	}

	get problem_params() { return this._problem_params; }

	get all_field_names() {
		return [ ...super.all_field_names, ...['set_problem_id', 'set_id', 'problem_number', 'problem_params']];
	}

	get param_fields() { return [...super.param_fields, ...['problem_params'] ]; }

	public get set_problem_id() : number { return this._set_problem_id; }
	public set set_problem_id(val: number) { this._set_problem_id = val;}

	public get set_id() : number { return this._set_id; }
	public set set_id(val: number) { this._set_id = val;}

	get problem_number(): number { return this._problem_number; }
	set problem_number(val: number) { this._problem_number = val; }

	clone(): SetProblem {
		return new SetProblem(this.toObject());
	}

	path(): string {
		return this.problem_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.problem_params.file_path ?? '';
		return p;
	}

	isValid() {
		return isNonNegInt(this.set_problem_id) && isNonNegInt(this.set_id) &&
			isNonNegInt(this.problem_number) && this.problem_params.isValid();
	}
}

export interface ParseableDBUserProblem {
	render_params?: RenderParams;
	problem_params?: ParseableSetProblemParams;
	set_problem_id?: number;
	user_problem_id?: number;
	user_set_id?: number;
	seed?: number;
	status?: number;
	problem_version?: number;
}

/**
 * The class DBUserProblem is used for problems assigned to Users and
 * to be used to store in the database.  This is used only in the store.
 */

export class DBUserProblem extends Problem {
	private _problem_params = new SetProblemParams();
	private _user_problem_id = 0;
	private _set_problem_id = 0;
	private _user_set_id = 0;
	private _seed = 0;
	private _status = 0;
	private _problem_version = 1;

	constructor(params: ParseableDBUserProblem = {}) {
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

	set(params: ParseableDBUserProblem) {
		if (params.set_problem_id != undefined) this.set_problem_id = params.set_problem_id;
		if (params.user_set_id != undefined) this.user_set_id = params.user_set_id;
		if (params.user_problem_id != undefined) this.user_problem_id = params.user_problem_id;
		if (params.seed != undefined) this.seed = params.seed;
		if (params.status != undefined) this.status = params.status;
		if (params.problem_version != undefined) this.problem_version = params.problem_version;
	}

	static ALL_FIELDS = ['user_problem_id', 'set_problem_id', 'user_set_id', 'seed', 'status',
		'problem_version', 'render_params', 'problem_params'];

	get problem_params() { return this._problem_params; }
	get all_field_names() { return DBUserProblem.ALL_FIELDS; }

	get param_fields() { return ['problem_params', 'render_params']; }

	public get set_problem_id() : number { return this._set_problem_id; }
	public set set_problem_id(val: number) { this._set_problem_id = val;}

	public get user_problem_id() : number { return this._user_problem_id; }
	public set user_problem_id(val: number) { this._user_problem_id = val;}

	public get user_set_id() : number { return this._user_set_id; }
	public set user_set_id(val: number) { this._user_set_id = val;}

	public get seed() : number { return this._seed; }
	public set seed(val: number) { this._seed = val;}

	public get status() : number { return this._status; }
	public set status(val: number) { this._status = val;}

	public get problem_version() : number { return this._problem_version; }
	public set problem_version(val: number) { this._problem_version = val;}

	public clone() {
		return new DBUserProblem(this.toObject());
	}

	path(): string {
		return this.problem_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.problem_params.file_path ?? '';
		p.problemSeed = this.seed;
		return p;
	}

	isValid(): boolean {
		return isNonNegInt(this.set_problem_id) && isNonNegInt(this._user_problem_id) &&
			isNonNegInt(this.user_set_id) && isNonNegInt(this.seed) && isNonNegDecimal(this.status) &&
			isNonNegInt(this.problem_version) && this.problem_params.isValid();
	}
}

// This next section is related to UserProblems which is a merge between
// a DBUserProblem, SetProblem and a CourseUser.

export interface ParseableUserProblem {
	render_params?: ParseableRenderParams;
	problem_params?: ParseableSetProblemParams;
	set_problem_id?: number;
	user_problem_id?: number;
	user_id?: number;
	user_set_id?: number;
	set_id?: number;
	seed?: number;
	status?: number;
	problem_version?: number;
	problem_number?: number;
	username?: string;
	set_name?: string;
}

/**
 * The class UserProblem is used for merging User and set problems
 */

export class UserProblem extends Problem {
	private _problem_params = new SetProblemParams();
	private _user_problem_id = 0;
	private _set_problem_id = 0;
	private _user_id = 0;
	private _user_set_id = 0;
	private _set_id = 0;
	private _seed = 0;
	private _status = 0;
	private _problem_version = 1;
	private _problem_number = 0;
	private _username = '';
	private _set_name = '';

	constructor(params: ParseableUserProblem = {}) {
		super(params);
		this.set(params);
		this._problem_type = ProblemType.USER;
		if (params.problem_params) this._problem_params.set(params.problem_params);

		// For merged user problems, preview and check answer are on my default.
		this.setRenderParams({
			showSolutions: false,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: false,
			answerPrefix: `${this.problem_type}${this.problem_number}_`,
		});
	}

	set(params: ParseableUserProblem) {
		if (params.set_problem_id != undefined) this.set_problem_id = params.set_problem_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.user_set_id != undefined) this.user_set_id = params.user_set_id;
		if (params.user_problem_id != undefined) this.user_problem_id = params.user_problem_id;
		if (params.seed != undefined) this.seed = params.seed;
		if (params.status != undefined) this.status = params.status;
		if (params.problem_version != undefined) this.problem_version = params.problem_version;
		if (params.problem_number != undefined) this.problem_number = params.problem_number;
		if (params.username) this.username = params.username;
		if (params.set_name) this.set_name = params.set_name;
	}

	static ALL_FIELDS = ['user_problem_id', 'set_problem_id', 'user_id', 'user_set_id', 'seed', 'status',
		'problem_number', 'username', 'set_name', 'problem_version', 'problem_params', 'render_params'];

	get all_field_names() {
		return UserProblem.ALL_FIELDS;
	}

	get param_fields() { return ['problem_params', 'render_params']; }

	public get problem_params() { return this._problem_params; }

	public get set_problem_id() : number { return this._set_problem_id; }
	public set set_problem_id(val: number) { this._set_problem_id = val;}

	public get user_problem_id() : number { return this._user_problem_id; }
	public set user_problem_id(val: number) { this._user_problem_id = val;}

	public get user_id() : number { return this._user_id; }
	public set user_id(val: number) { this._user_id = val;}

	public get user_set_id() : number { return this._user_set_id; }
	public set user_set_id(val: number) { this._user_set_id = val;}

	public get set_id() : number { return this._set_id; }
	public set set_id(val: number) { this._set_id = val;}

	public get seed() : number { return this._seed; }
	public set seed(val: number) { this._seed = val;}

	public get status() : number { return this._status; }
	public set status(val: number) { this._status = val;}

	public get problem_version() : number { return this._problem_version; }
	public set problem_version(val: number) { this._problem_version = val;}

	public get problem_number() : number { return this._problem_number; }
	public set problem_number(val: number) { this._problem_number = val;}

	public get username() : string { return this._username; }
	public set username(val: string) { this._username = val; }

	public get set_name() : string { return this._set_name; }
	public set set_name(val: string) { this._set_name = val;}

	public clone() {
		return new UserProblem(this.toObject() as unknown as ParseableUserProblem);
	}

	path(): string {
		return this._problem_params.file_path ?? '';
	}

	requestParams(): ParseableRenderParams {
		const p = super.requestParams();
		p.sourceFilePath = this.path();
		return p;
	}

	isValid() {
		return isNonNegInt(this.set_problem_id) && isNonNegInt(this._user_problem_id) &&
			isNonNegInt(this.user_id) && isNonNegInt(this.user_set_id) && isNonNegInt(this.set_id) &&
			isNonNegInt(this.seed) && isNonNegDecimal(this.status) && isNonNegInt(this.problem_number) &&
			isNonNegInt(this.problem_version) && this.problem_params.isValid() &&
			isValidUsername(this.username) && this.set_name.length > 0;
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

/**
 * Merges a SetProblem, a DBUserProblem and a UserSet returning a UserProblem.
 * Note: if the arguments are not related in the database (based on primary and foreign keys)
 * A MergeError is thrown.
 */

export function mergeUserProblem(set_problem: SetProblem, db_user_problem: DBUserProblem,
	user_set: UserSet) {
	// Check if the User Problem is related to the Set Problem
	if (set_problem.set_problem_id !== db_user_problem.set_problem_id) {
		throw new MergeError('The User set is not related to the Problem set');
	}
	// Check if the user problem is related to the user set.
	if (user_set.user_set_id !== db_user_problem.user_set_id) {
		throw new MergeError('The Merged user is not related to the user set.');
	}
	const user_problem: ParseableUserProblem = {
		set_problem_id: db_user_problem.set_problem_id,
		user_problem_id: db_user_problem.user_problem_id,
		user_id: user_set.user_id,
		set_id: user_set.set_id,
		user_set_id: user_set.user_set_id,
		username: user_set.username,
		set_name: user_set.set_name,
		problem_version: db_user_problem.problem_version,
		problem_number: set_problem.problem_number,
		status: db_user_problem.status,
		seed: db_user_problem.seed
	};

	// override set params
	const params = set_problem.problem_params.toObject() as Dictionary<generic>;
	const user_params = db_user_problem.problem_params.toObject() as Dictionary<generic>;
	Object.keys(user_params).forEach(key => {
		if (user_params[key] !== undefined) params[key] = user_params[key];
	});
	user_problem.problem_params = params;

	return new UserProblem(user_problem);
}

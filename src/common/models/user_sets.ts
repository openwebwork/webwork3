/**
 * This defines UserSets and MergedUserSets
 */

import { Model } from '.';
import { parseBoolean, parseNonNegInt, parseUsername } from './parsers';
import { ProblemSetDates, ProblemSetParams, HomeworkSetParams, HomeworkSetDates,
	ParseableHomeworkSetParams, ParseableHomeworkSetDates, QuizParams, QuizDates,
	ParseableQuizDates, ParseableQuizParams, ParseableReviewSetDates,
	ParseableReviewSetParams, ReviewSetDates, ReviewSetParams, ProblemSetType,
	ProblemSet, ParseableProblemSetParams, ParseableProblemSetDates } from './problem_sets';
import { MergedUser } from './users';

export interface ParseableUserSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_type?: string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_params?: ParseableProblemSetParams;
	set_dates?: ParseableProblemSetDates;
}

export class UserSet extends Model {
	private _user_set_id = 0;
	private _set_id = 0;
	private _course_user_id = 0;
	private _set_version = 1;
	private _set_visible?: boolean;
	protected _set_type: ProblemSetType = ProblemSetType.UNKNOWN;

	get set_dates(): ProblemSetDates { throw 'The subclass must override set_dates()'; }
	get set_params(): ProblemSetParams { throw 'The subclass must override set_dates()'; }

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'set_visible'];

	get all_field_names(): string[] {
		return UserSet.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return [];
	}

	// This should only be readable.  There is no setter.
	get set_type() { return this._set_type; }

	constructor(params: ParseableUserSet = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableUserSet) {
		if (params.user_set_id) this.user_set_id = params.user_set_id;
		if (params.set_id) this.set_id = params.set_id;
		if (params.course_user_id) this.course_user_id = params.course_user_id;
		if (params.set_version) this.set_version = params.set_version;
		if (params.set_visible) this._set_visible = parseBoolean(params.set_visible);
	}

	public get user_set_id(): number { return this._user_set_id;}
	public set user_set_id(value: number | string) { this._user_set_id = parseNonNegInt(value);}

	public get set_id(): number { return this._set_id;}
	public set set_id(value: number | string) { this._set_id = parseNonNegInt(value);}

	public get course_user_id(): number { return this._course_user_id;}
	public set course_user_id(value: number | string) { this._course_user_id = parseNonNegInt(value);}

	public get set_version(): number { return this._set_version;}
	public set set_version(value: number | string) { this._set_version = parseNonNegInt(value);}

	public get set_visible(): boolean | undefined { return this._set_visible;}
	public set set_visible(value: number | string | boolean | undefined) {
		if (value) this._set_visible = parseBoolean(value);
	}

	public hasValidDates(): boolean {
		throw 'The subclass must override the hasValidDates() method.';
	}

	public clone() {
		return new UserSet(this.toObject());
	}
}

/**
 * UserHomeworkSet is a HomeworkSet for a User
 */

export interface ParseableUserHomeworkSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_params?: ParseableHomeworkSetParams;
	set_dates?: ParseableHomeworkSetDates;
}

export class UserHomeworkSet extends UserSet {
	private _set_params = new HomeworkSetParams();
	private _set_dates = new HomeworkSetDates();

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_visible', 'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return UserHomeworkSet.ALL_FIELDS;
	}
	get param_fields(): string[] {
		return ['set_params', 'set_dates'];
	}
	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableUserHomeworkSet = {}) {
		super(params as ParseableUserSet);
		this._set_type = ProblemSetType.HW;
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid({ enable_reduced_scoring: this.set_params.enable_reduced_scoring });
	}

	public clone() {
		return new UserHomeworkSet(this.toObject());
	}
}

/**
 * UserQuiz is a Quiz for a User
 */

export interface ParseableUserQuiz {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_params?: ParseableQuizParams;
	set_dates?: ParseableQuizDates;
}

export class UserQuiz extends UserSet {
	private _set_params = new QuizParams();
	private _set_dates = new QuizDates();

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_visible', 'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return UserQuiz.ALL_FIELDS;
	}

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}
	get param_fields(): string[] {
		return ['set_params', 'set_dates'];
	}

	constructor(params: ParseableUserQuiz = {}) {
		super(params as ParseableUserSet);
		this._set_type = ProblemSetType.QUIZ;
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid();
	}

	public clone() {
		return new UserQuiz(this.toObject());
	}
}

/**
 * UserReviewSet is a ReviewSet for a User
 */

export interface ParseableUserReviewSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_params?: ParseableReviewSetParams;
	set_dates?: ParseableReviewSetDates;
}

export class UserReviewSet extends UserSet {
	private _set_params = new ReviewSetParams();
	private _set_dates = new ReviewSetDates({ open: 0, closed: 0 });

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_visible', 'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return UserReviewSet.ALL_FIELDS;
	}

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}
	get param_fields(): string[] {
		return ['set_params', 'set_dates'];
	}

	constructor(params: ParseableUserReviewSet = {}) {
		super(params as ParseableUserSet);
		this._set_type = ProblemSetType.REVIEW_SET;
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid();
	}

	public clone() {
		return new UserReviewSet(this.toObject());
	}
}

export function parseUserSet(user_set: ParseableUserSet) {
	if (user_set.set_type === 'HW') {
		return new UserHomeworkSet(user_set as ParseableUserHomeworkSet);
	} else if (user_set.set_type === 'QUIZ') {
		return new UserQuiz(user_set as ParseableUserQuiz);
	} else if (user_set.set_type === 'REVIEW') {
		return new UserReviewSet(user_set as ParseableUserReviewSet);
	} else {
		return new UserSet(user_set);
	}
}

/**
 * MergedUserSet is a structure that is a joined version of a UserSet and a ProblemSet
 */

export interface ParseableMergedUserSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_name?: string;
	username?: string;
	set_type?: string;
	set_params?: ParseableProblemSetParams;
	set_dates?: ParseableProblemSetDates;
}

export class MergedUserSet extends Model {
	private _user_set_id = 0;
	private _set_id = 0;
	private _course_user_id = 0;
	private _user_id = 0;
	protected _set_type = '';
	private _set_version = 1;
	private _set_visible?: boolean;
	private _set_name = '';
	private _username = '';

	get set_dates(): ProblemSetDates { throw 'The subclass must override set_dates()'; }
	get set_params(): ProblemSetParams { throw 'The subclass must override set_dates()'; }

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'user_id', 'set_version',
		'set_visible', 'set_name', 'username',
		'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return MergedUserSet.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['set_params', 'set_dates'];
	}

	get set_type() { return this._set_type; }

	constructor(params: ParseableMergedUserSet = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableMergedUserSet) {
		if (params.user_set_id != undefined) this.user_set_id = params.user_set_id;
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.set_version != undefined) this.set_version = params.set_version;
		if (params.set_visible != undefined) this.set_visible = params.set_visible;
		if (params.set_name) this.set_name = params.set_name;
		if (params.username) this.username = params.username;
	}

	public get user_set_id(): number { return this._user_set_id;}
	public set user_set_id(value: number | string) { this._user_set_id = parseNonNegInt(value);}

	public get set_id(): number { return this._set_id;}
	public set set_id(value: number | string) { this._set_id = parseNonNegInt(value);}

	public get course_user_id(): number { return this._course_user_id;}
	public set course_user_id(value: number | string) { this._course_user_id = parseNonNegInt(value);}

	public get user_id(): number { return this._user_id;}
	public set user_id(value: number | string) { this._user_id = parseNonNegInt(value);}

	public get set_version(): number { return this._set_version;}
	public set set_version(value: number | string) { this._set_version = parseNonNegInt(value);}

	public get set_visible(): boolean | undefined { return this._set_visible; }
	public set set_visible(value: number | string | boolean | undefined) {
		if (value) {
			this._set_visible = parseBoolean(value);
		}
	}

	public get set_name(): string { return this._set_name; }
	public set set_name(value: string) { this._set_name = value; }

	public get username(): string { return this._username; }
	public set username(value: string) { this._username = parseUsername(value);}

	clone(): MergedUserSet {
		throw 'the clone() method should be overridden in a subclass of MergedUserSet';
	}
}

/**
 * MergedUserHomeworkSet is joined HomeworkSet and a UserSet
 */

export interface ParseableMergedUserHomeworkSet {
	user_id?: number | string;
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_name?: string;
	username?: string;
	set_type?: string;
	set_params?: ParseableHomeworkSetParams;
	set_dates?: ParseableHomeworkSetDates;
}

export class MergedUserHomeworkSet extends MergedUserSet {
	private _set_params = new HomeworkSetParams();
	private _set_dates = new HomeworkSetDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableMergedUserHomeworkSet = {}) {
		super(params as ParseableMergedUserSet);
		this._set_type = 'HW';
		if (params.set_params) this.set_params.set(params.set_params);
		if (params.set_dates) this.set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid({ enable_reduced_scoring: this.set_params.enable_reduced_scoring });
	}

	public clone(): MergedUserHomeworkSet {
		return new MergedUserHomeworkSet(this.toObject());
	}
}

/**
 * MergedUserQuiz is a Quiz merged with a UserSet
 */

export interface ParseableMergedUserQuiz {
	user_set_id?: number | string;
	user_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_visible?: number | string | boolean;
	set_name?: string;
	username?: string;
	set_params?: ParseableQuizParams;
	set_dates?: ParseableQuizDates;
	set_type?: string;
}

export class MergedUserQuiz extends MergedUserSet {
	private _set_params = new QuizParams();
	private _set_dates = new QuizDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableMergedUserQuiz = {}) {
		super(params as ParseableMergedUserSet);
		this._set_type = 'QUIZ';
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid();
	}

	public clone() {
		return new MergedUserQuiz(this.toObject());
	}
}

/**
 * MergedUserReviewSet is ReviewSet for a User
 */

export interface ParseableMergedUserReviewSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_type?: string;
	set_params?: ParseableReviewSetParams;
	set_dates?: ParseableReviewSetDates;
}

export class MergedUserReviewSet extends MergedUserSet {
	private _set_params = new ReviewSetParams();
	private _set_dates = new ReviewSetDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableMergedUserReviewSet = {}) {
		super(params as ParseableMergedUserSet);
		this._set_type = 'REVIEW';
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public hasValidDates() {
		return this.set_dates.isValid();
	}

	public clone() {
		return new MergedUserReviewSet(this.toObject());
	}
}

export function parseMergedUserSet(user_set: ParseableMergedUserSet) {
	if (user_set.set_type === 'HW') {
		return new MergedUserHomeworkSet(user_set as ParseableMergedUserHomeworkSet);
	} else if (user_set.set_type === 'QUIZ') {
		return new MergedUserQuiz(user_set as ParseableMergedUserQuiz);
	} else if (user_set.set_type === 'REVIEW') {
		return new MergedUserReviewSet(user_set as ParseableMergedUserReviewSet);
	}
}

class MergingError extends Error {
	constructor(str: string) {
		super(str);
	}
};

/**
 * merge a ProblemSet and a UserSet in that the result is a MergedUserSet with overrides
 * taken from the UserSet.  Additional info is taken from the MergedUser instance.
 * @param {ProblemSet} set - a problem set
 * @param {UserSet} user_set - a user set that will override the problem set dates and parameters.
 * @param {MergedUser} user - the user associated with the set.
 * @returns a MergedUserSet with the appropriate overrides.
 */
export function mergeUserSet(set: ProblemSet, user_set: UserSet, user: MergedUser) {
	// Check if the user_set is related to the Problem Set
	if (set.set_id !== user_set.set_id) {
		throw new MergingError('The User set is not related to the Problem set');
	}
	// Check if the user is related to the user set.
	if (user_set.course_user_id !== user.course_user_id) {
		throw new MergingError('The Merged user is not related to the user set.');
	}
	const merged_user_set: ParseableMergedUserSet = {
		user_id: user.user_id,
		course_user_id: user.course_user_id,
		username: user.username,
		set_id: set.set_id,
		user_set_id: user_set.user_set_id,
		set_name: set.set_name,
		set_type: set.set_type,
		set_visible: user_set.set_visible,
		set_version: user_set.set_version
	};

	// override set params
	const params = set.set_params.toObject();
	const user_params = user_set.set_params.toObject();
	Object.keys(user_params).forEach(key => {
		if (user_params[key] !== undefined) params[key] = user_params[key];
	});
	merged_user_set.set_params = params;

	// override set dates
	const dates = set.set_dates.toObject();
	const user_dates = user_set.set_dates.toObject();
	Object.keys(user_dates).forEach(key => {
		if (user_dates[key] != undefined) dates[key] = user_dates[key];
	});
	merged_user_set.set_dates = dates;
	return parseMergedUserSet(merged_user_set);
}

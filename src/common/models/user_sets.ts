/**
 * This defines UserSets for the database (DBUserSet) and a UserSet (merged version
 * between a DBUserSet and a ProblemSt))
 */

import { Model } from '.';
import { isNonNegInt, isValidUsername, MergeError } from './parsers';
import { ProblemSetDates, ProblemSetParams, HomeworkSetParams, HomeworkSetDates,
	ParseableHomeworkSetParams, ParseableHomeworkSetDates, QuizParams, QuizDates,
	ParseableQuizDates, ParseableQuizParams, ParseableReviewSetDates,
	ParseableReviewSetParams, ReviewSetDates, ReviewSetParams, ProblemSetType,
	ProblemSet, ParseableProblemSetParams, ParseableProblemSetDates } from './problem_sets';
import { CourseUser } from './users';

type UserSetDates = UserHomeworkSetDates | UserQuizDates | UserReviewSetDates;
type UserSetParams = UserHomeworkSetParams | UserQuizParams | UserReviewSetParams;

// The ParseableDBUserSet type is the same as the ParseableProblemSet type
// with additional fields. This mimics the UserSet fields on the database.

export type ParseableDBUserSet = {
	user_set_id?: number;
	set_version?: number;
	course_user_id?: number;
	set_id?: number;
	set_type?: string;
	set_visible?: boolean;
	set_params?: ParseableProblemSetParams;
	set_dates?: ParseableProblemSetDates;
}

/**
 * The DBUserSet is used for overrides for a ProblemSet and in the client-side model
 * of the UserSet on the database.  Note: this has changed recently
 * to reflect that the UserSet should be independent of a ProblemSet (not inherit from it).
 */
export class DBUserSet extends Model {
	private _user_set_id = 0;
	private _course_user_id = 0;
	private _set_id = 0;
	protected _set_type = ProblemSetType.UNKNOWN;
	private _set_version = 1;
	private _set_visible?: boolean;

	get set_dates(): UserSetDates { throw 'The subclass must override set_dates()'; }
	get set_params(): UserSetParams { throw 'The subclass must override set_dates()'; }

	static ALL_FIELDS = ['user_set_id', 'set_id', 'set_type', 'course_user_id', 'set_version', 'set_visible'];

	get all_field_names(): string[] { return DBUserSet.ALL_FIELDS; }
	get param_fields(): string [] { return []; }

	// This should only be readable.  There is no setter.
	get set_type() { return this._set_type; }

	constructor(params: ParseableDBUserSet = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableDBUserSet) {
		if (params.user_set_id != undefined) this.user_set_id = params.user_set_id;
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		if (params.set_version != undefined) this.set_version = params.set_version;
		if (params.set_id != undefined) this.set_id = params.set_id;
		this.set_visible = params.set_visible;
	}

	public get user_set_id(): number { return this._user_set_id;}
	public set user_set_id(value: number) { this._user_set_id = value;}

	public get set_id(): number { return this._set_id;}
	public set set_id(value: number) { this._set_id = value;}

	public get course_user_id(): number { return this._course_user_id;}
	public set course_user_id(value: number) { this._course_user_id = value;}

	public get set_version(): number { return this._set_version;}
	public set set_version(value: number) { this._set_version = value;}

	public get set_visible(): boolean | undefined { return this._set_visible; }
	public set set_visible(value: boolean | undefined) { this._set_visible = value;}

	public clone() {
		return new DBUserSet(this.toObject());
	}

	public isValid(): boolean {
		return isNonNegInt(this.user_set_id) && isNonNegInt(this.set_id) &&
			isNonNegInt(this.course_user_id) && isNonNegInt(this.set_version);
	}
}

/**
 * UserHomeworkSet is a HomeworkSet for a User
 */

export type ParseableDBUserHomeworkSet = ParseableDBUserSet &
	{
		set_params?: ParseableHomeworkSetParams;
		set_dates?: ParseableHomeworkSetDates;
	}

/**
 * This is nearly identical to the HomeworkSetDates model except that any of the
 * date fields can be undefined.
 */
export class UserHomeworkSetDates extends Model {
	private _open?: number;
	private _reduced_scoring?: number;
	private _due?: number;
	private _answer?: number;
	private _enable_reduced_scoring?: boolean;

	static ALL_FIELDS = ['open', 'reduced_scoring', 'due', 'answer', 'enable_reduced_scoring'];
	get all_field_names(): string[] { return UserHomeworkSetDates.ALL_FIELDS; }
	get param_fields(): string[] { return [];}

	constructor(params: ParseableHomeworkSetDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableHomeworkSetDates) {
		this.open = params.open;
		this.reduced_scoring = params.reduced_scoring;
		this.due = params.due;
		this.answer = params.answer;
		this.enable_reduced_scoring = params.enable_reduced_scoring;
	}

	public get open(): number | undefined { return this._open;}
	public set open(value: number | undefined) { this._open = value;}

	public get reduced_scoring(): number | undefined { return this._reduced_scoring;}
	public set reduced_scoring(value: number | undefined) { this._reduced_scoring = value; }

	public get due(): number | undefined { return this._due;}
	public set due(value: number | undefined) { this._due = value; }

	public get answer() : number | undefined { return this._answer;}
	public set answer(value: number | undefined) { this._answer = value; }

	public get enable_reduced_scoring(): boolean | undefined { return this._enable_reduced_scoring; }
	public set enable_reduced_scoring(value: boolean | undefined) { this._enable_reduced_scoring = value; }

	public isValid() {
		if (this.enable_reduced_scoring && this.reduced_scoring == undefined) return false;
		if (this.enable_reduced_scoring && this.reduced_scoring != undefined &&
			this.open != undefined && this.open > this.reduced_scoring) return false;
		if (this.enable_reduced_scoring && this.reduced_scoring != undefined &&
			this.due != undefined && this.reduced_scoring > this.due) return false;
		if (this.enable_reduced_scoring && this.reduced_scoring != undefined &&
			this.answer != undefined && this.reduced_scoring > this.answer) return false;
		if (this.open != undefined && this.due != undefined && this.open > this.due) return false;
		if (this.open != undefined && this.answer != undefined && this.open > this.answer) return false;
		if (this.due != undefined && this.answer != undefined && this.due > this.answer) return false;
		return true;
	}

	public clone(): UserHomeworkSetDates {
		return new UserHomeworkSetDates(this.toObject());
	}
}

/**
 * This is nearly identical to the HomeworkSetParams except that all fields are optional
 */

export class UserHomeworkSetParams extends Model {
	private _hide_hint?: boolean;
	private _hardcopy_header?: string;
	private _set_header?: string;
	private _description?: string;

	static ALL_FIELDS = ['hide_hint', 'hardcopy_header', 'set_header', 'description'];

	get all_field_names(): string[] {
		return HomeworkSetParams.ALL_FIELDS;
	}
	get param_fields(): string[] { return [];}

	constructor(params: ParseableHomeworkSetParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableHomeworkSetParams) {
		this.hide_hint = params.hide_hint;
		this.hardcopy_header = params.hardcopy_header;
		this.set_header = params.set_header;
		this.description = params.description;
	}

	public get hide_hint() : boolean | undefined { return this._hide_hint;}
	public set hide_hint(value: boolean | undefined) { this._hide_hint = value; }

	public get hardcopy_header() : string | undefined { return this._hardcopy_header;}
	public set hardcopy_header(value: string | undefined) { this._hardcopy_header = value; }

	public get set_header() : string | undefined { return this._set_header;}
	public set set_header(value: string | undefined) { this._set_header = value; }

	public get description() : string | undefined { return this._description;}
	public set description(value: string | undefined) { this._description = value; }

	isValid(): boolean {
		return true;
	}

	clone(): UserHomeworkSetParams {
		return new UserHomeworkSetParams(this.toObject());
	}
}

export class DBUserHomeworkSet extends DBUserSet {
	private _set_params = new UserHomeworkSetParams();
	private _set_dates = new UserHomeworkSetDates();

	static ALL_FIELDS = [ ...DBUserSet.ALL_FIELDS, ...['set_params', 'set_dates']];

	get all_field_names(): string[] { return DBUserHomeworkSet.ALL_FIELDS; }
	get param_fields(): string[] { return ['set_params', 'set_dates']; }

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableDBUserHomeworkSet = {}) {
		super(params as ParseableDBUserSet);
		this._set_type = ProblemSetType.HW;
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}
	public clone() {
		return new DBUserHomeworkSet(this.toObject());
	}
}

/**
 * DBUserQuiz stores a user quiz that mimics that on the database. This is used
 * in the store as a transition to the database.
 */

export type ParseableDBUserQuiz  = ParseableDBUserSet &
	{
		set_params?: ParseableQuizParams;
		set_dates?: ParseableQuizDates;
	}

export class UserQuizDates extends Model {
	protected _open?: number;
	protected _due?: number;
	protected _answer?: number;

	constructor(params: ParseableQuizDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableQuizDates) {
		if (params.open != undefined) this.open = params.open;
		if (params.due != undefined) this.due = params.due;
		if (params.answer != undefined) this.answer = params.answer;
	}

	get all_field_names(): string[] {
		return ['open', 'due', 'answer'];
	}
	get param_fields(): string[] { return [];}

	public get open(): number | undefined { return this._open;}
	public set open(value: number | undefined) {
		if (value != undefined) this._open = value;
	}

	public get due(): number | undefined { return this._due;}
	public set due(value: number | undefined) {
		if (value != undefined) this._due = value;
	}

	public get answer() : number | undefined { return this._answer;}
	public set answer(value: number | undefined) {
		if (value != undefined) this._answer = value;
	}

	public isValid() {
		if (this.open != undefined && this.due != undefined && this.open > this. due) return false;
		if (this.due != undefined && this.answer != undefined && this.due > this.answer) return false;
		return true;
	}

	public clone(): UserQuizDates {
		return new UserQuizDates(this.toObject());
	}
}

/**
 * This is nearly identical to the QuizParams model except that the fields can
 * each be undefined.
 */

export class UserQuizParams extends Model {
	private _timed?: boolean;
	private _quiz_duration?: number;

	constructor(params: ParseableQuizParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableQuizParams) {
		if (params.timed != undefined) this.timed = params.timed;
		if (params.quiz_duration) this.quiz_duration = params.quiz_duration;
	}

	static ALL_FIELDS = ['timed', 'quiz_duration'];
	get all_field_names(): string[] { return QuizParams.ALL_FIELDS; }
	get param_fields(): string[] { return [];}

	public get timed() : boolean | undefined { return this._timed;}
	public set timed(value: boolean | undefined) { this._timed = value;}

	public get quiz_duration(): number | undefined { return this._quiz_duration;}
	public set quiz_duration(value: number | undefined) { this._quiz_duration = value;}

	clone(): QuizParams {
		return new QuizParams(this.toObject());
	}

	isValid(): boolean {
		return this.quiz_duration != undefined && isNonNegInt(this.quiz_duration);
	}
}

export class DBUserQuiz extends DBUserSet {
	private _set_params = new UserQuizParams();
	private _set_dates = new UserQuizDates();

	static ALL_FIELDS = [ ...DBUserSet.ALL_FIELDS, ...['set_params', 'set_dates']];

	get all_field_names(): string[] { return DBUserQuiz.ALL_FIELDS; }

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}
	get param_fields(): string[] { return ['set_params', 'set_dates']; }

	constructor(params: ParseableUserQuiz = {}) {
		super(params as ParseableDBUserSet);
		this._set_type = ProblemSetType.QUIZ;
		if (params.set_params) this._set_params.set(params.set_params as ParseableQuizParams);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}
	public clone() {
		return new DBUserQuiz(this.toObject());
	}
}

/**
 * DBUserReviewSet stores a user review set that mimics that on the database. This is used
 * in the store as a transition to the database.
 */

export type ParseableDBUserReviewSet = ParseableDBUserSet &
	{
		set_params?: ParseableReviewSetParams;
		set_dates?: ParseableReviewSetDates;
	}

export class UserReviewSetDates extends Model {
	protected _open?: number;
	protected _closed?: number;

	constructor(params: ParseableReviewSetDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableReviewSetDates) {
		this.open = params.open;
		this.closed = params.closed;
	}

	get all_field_names(): string[] {
		return ['open', 'closed'];
	}
	get param_fields(): string[] { return [];}

	public get open(): number | undefined { return this._open;}
	public set open(value: number | undefined) {
		if (value != undefined) this._open = value;
	}

	public get closed(): number | undefined { return this._closed;}
	public set closed(value: number | undefined) {
		if (value != undefined) this._closed = value;
	}

	public isValid(): boolean {
		if (this.open != undefined && this.closed != undefined && this.open > this.closed) return false;
		return true;
	}

	public clone(): UserReviewSetDates {
		return new UserReviewSetDates(this.toObject());
	}
}

/**
 * This is nearly identical to ReviewSetParams except all fields can be undefined.
 */

export class UserReviewSetParams extends Model {
	private _can_retake?: boolean;

	constructor(params: ParseableReviewSetParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableReviewSetParams) {
		this.can_retake = params.can_retake;
	}

	static ALL_FIELDS = ['can_retakes'];
	get all_field_names(): string[] { return UserReviewSetParams.ALL_FIELDS; }
	get param_fields(): string[] { return [];}

	public get can_retake() : boolean | undefined { return this._can_retake;}
	public set can_retake(value: boolean | undefined) { this._can_retake = value; }

	isValid(): boolean {
		return true;
	}
}

export class DBUserReviewSet extends DBUserSet {
	private _set_params = new UserReviewSetParams();
	private _set_dates = new UserReviewSetDates();

	static ALL_FIELDS = [ ...DBUserSet.ALL_FIELDS, ...['set_params', 'set_dates']];

	get param_fields(): string[] { return ['set_params', 'set_dates']; }
	get all_field_names(): string[] { return DBUserReviewSet.ALL_FIELDS; }

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableDBUserReviewSet = {}) {
		super(params as ParseableDBUserSet);
		this._set_type = ProblemSetType.REVIEW_SET;
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public clone() {
		return new DBUserReviewSet(this.toObject());
	}
}

export function parseDBUserSet(user_set: ParseableDBUserSet) {
	if (user_set.set_type === 'HW') {
		return new DBUserHomeworkSet(user_set as ParseableDBUserHomeworkSet);
	} else if (user_set.set_type === 'QUIZ') {
		return new DBUserQuiz(user_set as ParseableDBUserQuiz);
	} else if (user_set.set_type === 'REVIEW') {
		return new DBUserReviewSet(user_set as ParseableDBUserReviewSet);
	} else {
		return new DBUserSet(user_set);
	}
}

/**
 * UserSet is a structure that is a joined version of a DBUserSet and a ProblemSet
 */

export interface ParseableUserSet {
	user_set_id?: number;
	set_id?: number;
	course_user_id?: number;
	user_id?: number;
	set_version?: number;
	set_visible?: boolean;
	set_name?: string;
	username?: string;
	set_type?: string;
	set_params?: ParseableProblemSetParams;
	set_dates?: ParseableProblemSetDates;
}

export class UserSet extends Model {
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
		'set_visible', 'set_name', 'username', 'set_type', 'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return UserSet.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['set_params', 'set_dates'];
	}

	get set_type() { return this._set_type; }

	constructor(params: ParseableUserSet = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableUserSet) {
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
	public set user_set_id(value: number) { this._user_set_id = value;}

	public get set_id(): number { return this._set_id;}
	public set set_id(value: number) { this._set_id = value;}

	public get course_user_id(): number { return this._course_user_id;}
	public set course_user_id(value: number) { this._course_user_id = value;}

	public get user_id(): number { return this._user_id;}
	public set user_id(value: number) { this._user_id = value;}

	public get set_version(): number { return this._set_version;}
	public set set_version(value: number) { this._set_version = value;}

	public get set_visible(): boolean | undefined { return this._set_visible; }
	public set set_visible(value: boolean | undefined) {
		if (value != undefined) this._set_visible = value;
	}

	public get set_name(): string { return this._set_name; }
	public set set_name(value: string) { this._set_name = value; }

	public get username(): string { return this._username; }
	public set username(value: string) { this._username = value;}

	clone(): UserSet {
		throw 'the clone() method should be overridden in a subclass of UserSet';
	}

	public isValid(): boolean {
		return isNonNegInt(this.user_set_id) && isNonNegInt(this.set_id) &&
			isNonNegInt(this.course_user_id) && isNonNegInt(this.set_version) &&
			isNonNegInt(this.user_id) && isValidUsername(this.username) &&
			this.set_name.length > 0;
	}
}

/**
* UserHomeworkSet is joined HomeworkSet and a DBUserSet
*/

export type ParseableUserHomeworkSet = ParseableUserSet &
	{
		set_params?: ParseableHomeworkSetParams;
		set_dates?: ParseableHomeworkSetDates;
	}

export class UserHomeworkSet extends UserSet {
	private _set_params = new HomeworkSetParams();
	private _set_dates = new HomeworkSetDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableUserHomeworkSet = {}) {
		super(params as ParseableUserSet);
		this._set_type = 'HW';
		if (params.set_params) this.set_params.set(params.set_params);
		if (params.set_dates) this.set_dates.set(params.set_dates);
	}

	public clone(): UserHomeworkSet {
		return new UserHomeworkSet(this.toObject());
	}
}

/**
* UserQuiz is a Quiz merged with a DBUserSet
*/

export type ParseableUserQuiz = ParseableUserSet &
	{
		set_dates?: ParseableQuizDates;
		set_params?: ParseableQuizParams;
	}

export class UserQuiz extends UserSet {
	private _set_params = new QuizParams();
	private _set_dates = new QuizDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableUserQuiz = {}) {
		super(params as ParseableUserSet);
		this._set_type = 'QUIZ';
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public clone() {
		return new UserQuiz(this.toObject());
	}
}

/**
 * UserReviewSet is a join between a DBUserReviewSet and a ReviewSet
 */

export type ParseableUserReviewSet = ParseableUserSet &
	{
		set_params?: ParseableReviewSetParams;
		set_dates?: ParseableReviewSetDates;
	}

export class UserReviewSet extends UserSet {
	private _set_params = new ReviewSetParams();
	private _set_dates = new ReviewSetDates();

	get set_params() { return this._set_params;}
	get set_dates() { return this._set_dates;}

	constructor(params: ParseableUserReviewSet = {}) {
		super(params as ParseableUserSet);
		this._set_type = 'REVIEW';
		if (params.set_params) this._set_params.set(params.set_params);
		if (params.set_dates) this._set_dates.set(params.set_dates);
	}

	public clone() {
		return new UserReviewSet(this.toObject());
	}
}

/**
 * Parse the UserSet, returning a model of the correct subclass.
 */
export function parseUserSet(user_set: ParseableUserSet) {
	if (user_set.set_type === 'HW') {
		return new UserHomeworkSet(user_set as ParseableUserHomeworkSet);
	} else if (user_set.set_type === 'QUIZ') {
		return new UserQuiz(user_set as ParseableUserQuiz);
	} else if (user_set.set_type === 'REVIEW') {
		return new UserReviewSet(user_set as ParseableUserReviewSet);
	}
}

/**
 * Merge a ProblemSet, a DBUserSet and a User and return a UserSet. Note: if the
 * arguments are not related in the database (based on primary and foreign keys), a MergeError is thrown.
 * The result is a UserSet created with values from the DBUserSet and missing values taken from the ProblemSet.
 */
export function mergeUserSet(set: ProblemSet, db_user_set: DBUserSet, user: CourseUser): UserSet | undefined {
	// Perhaps we need to handle this better, but this situation happens when reacting
	// to changes between ProblemSets and UserSets in the store.
	if (set == undefined || db_user_set == undefined || user == undefined) return;
	// Check if the user_set is related to the Problem Set
	if (set.set_id !== db_user_set.set_id) {
		throw new MergeError('The User set is not related to the Problem set');
	}

	// Check if the user is related to the user set.
	if (db_user_set.course_user_id !== user.course_user_id) {
		throw new MergeError('The Course user is not related to the user set.');
	}
	const user_set: ParseableUserSet = {
		user_id: user.user_id,
		course_user_id: user.course_user_id,
		username: user.username,
		set_id: set.set_id,
		user_set_id: db_user_set.user_set_id,
		set_name: set.set_name,
		set_type: set.set_type,
		set_visible: db_user_set.set_visible ?? set.set_visible,
		set_version: db_user_set.set_version
	};

	// override set params
	const params = set.set_params.toObject();
	const user_params = db_user_set.set_params.toObject();
	Object.keys(user_params).forEach(key => {
		if (user_params[key] !== undefined) params[key] = user_params[key];
	});
	user_set.set_params = params;

	// override set dates
	const dates = set.set_dates.toObject();
	const user_dates = db_user_set.set_dates.toObject();
	Object.keys(user_dates).forEach(key => {
		if (user_dates[key] != undefined) dates[key] = user_dates[key];
	});
	user_set.set_dates = dates;
	return parseUserSet(user_set);
}

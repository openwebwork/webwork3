// This contains all of the interfaces for models throughout the app.

export interface Dictionary<T> {
	[key: string]: T;
}

export class Model {
	constructor(params: Dictionary<string|number|boolean>) {
		// parse the individual fields
		console.log(params);
		console.log(Object.keys(this));
	}

}

export const mailRE = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,9})/;
export const usernameRE = /^[a-zA-Z]([a-zA-Z._0-9])+$/;

function parseNonNegInt(val: string | number) {
	if (typeof val !== 'boolean' && (/\s*(\d+)\s*/.test(`${val}`))) {
		return parseInt(`${val}`);
	} else {
		throw `The value ${val.toString()} is not a non-negative integer`;
	}
}

function parseUsername(val: string | number) {
	if (typeof val === 'string' && (mailRE.test(`${val}`) || usernameRE.test(`${val}`))) {
		return val;
	} else {
		throw `The value ${val.toString()} is not a value username`;
	}
}

function parseEmail(val: string | number) {
	if (typeof val === 'string' && mailRE.test(`${val}`)) {
		return val;
	} else {
		throw `The value ${val.toString()} is not a value username`;
	}
}

export function parseBoolean(_value: boolean | string | number) {
	if (typeof _value === 'boolean') return _value;
	if (typeof _value === 'string' && !(/[01]/.exec(_value))) {
		return _value === 'true' || _value === 'false' ?
			_value === 'true' :
			undefined;
	} else {
		return _value === undefined ?
			undefined :
			parseInt(`${_value}`) === 1;
	}
}

export interface ParseableUser {
	user_id?: number | string;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: string | number | boolean;
	student_id?: string | number;
}

export class User  {
	_user_id: number;
	_username: string;
	_email: string;
	_first_name: string;
	_last_name: string;
	_is_admin: boolean;
	_student_id: string;

	constructor(params?: ParseableUser){
		this._user_id = params?.user_id ? parseNonNegInt(params?.user_id) : 0;
		this._username = params?.username ? parseUsername(params?.username) : '';
		this._email = params?.email ? parseEmail(params.email) : '';
		this._first_name = params?.first_name ?? '';
		this._last_name = params?.last_name ?? '';
		const admin = params?.is_admin ? parseBoolean(params?.is_admin) : false;
		this._is_admin = admin ?? false;
		this._student_id = params?.student_id?.toString() ?? '';
	}

	public set user_id(val: number) {
		this._user_id = parseNonNegInt(val);
	}

	public get user_id(): number {
		return this._user_id;
	}

	public set username(val: string) {
		this._username = parseUsername(val);
	}

	public get username(): string {
		return this._username;
	}

	public set first_name(val: string) {
		this._first_name = val.toString();
	}

	public get first_name(): string {
		return this._first_name;
	}

	public set last_name(val: string) {
		this._last_name = val.toString();
	}

	public get last_name(): string {
		return this._last_name;
	}

	public set is_admin(val: boolean) {
		this._is_admin = val;
	}

	public get is_admin(): boolean {
		return this._is_admin;
	}
}

export interface UserCourse {
	course_id: number;
	course_user_id: number;
	user_id: number;
	course_name: string;
	params: Dictionary<string>;
	recitation: string;
	section: string;
	role: string;
}

export interface CourseUser {
	course_user_id: number;
	course_id: number;
	role: string;
	section: string;
	recitation: string;
	params: Dictionary<string>;
}

export interface SessionInfo {
	user: User;
	logged_in: boolean;
	message: string;
}

export interface UserPassword {
	username: string;
	password: string;
}

export interface CourseDates {
	start: string;
	end: string;
}

export interface Course {
	course_id: number;
	course_name: string;
	visible: boolean;
	course_dates: CourseDates;
}

/* These are related to Course Settings */

export enum CourseSettingOption {
	int = 'int',
	decimal = 'decimal',
	list = 'list',
	multilist = 'multilist',
	text = 'text',
	boolean = 'boolean'
}

export interface CourseSetting {
	var: string;
	value: string | number | boolean;
}

export interface OptionType {
	label: string;
	value: string | number;
}

export interface CourseSettingInfo {
	var: string;
	category: string;
	doc: string;
	doc2: string;
	type: CourseSettingOption;
	options: Array<string> | Array<OptionType> | undefined;
	default: string | number | boolean;
}

/* These are Problem Set interfaces */

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW',
	UNKNOWN = 'UNKNOWN'
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DatesType {
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface ParamsType {
}

export interface HomeworkSetParams extends ParamsType {
	enable_reduced_scoring?: boolean;
	hide_hint?: boolean;
	hardcopy_header?: string;
	set_header?: string;
	description?: string;
}

export interface HomeworkSetDates {
	open: number;
	reduced_scoring?: number;
	due: number;
	answer:number;
}

export interface QuizDates extends DatesType {
	open: number;
	due: number;
	answer:number;
}

export interface QuizParams extends ParamsType {
	timed?: boolean;
	quiz_duration?: number;
}

export interface ReviewSetDates extends DatesType {
	open: number;
	closed: number;
}

export interface ReviewSetParams extends ParamsType {
	allow?: boolean;
}

export interface ResponseError {
	exception: string;
	message: string;
}

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id: string | number;
	set_name: string;
	course_id: string | number;
	set_type: string;
	set_visible: string | number;
	params: Dictionary<string>;
	dates: Dictionary<string>;
}

export class ProblemSet {
	set_id: number;
	set_name: string;
	course_id: number;
	set_type: ProblemSetType;
	set_visible: boolean;
	set_params: ParamsType;
	dates: DatesType;

	constructor(params?: ParseableProblemSet){
		this.set_id = params?.set_id ? parseNonNegInt(params?.set_id) : 0;
		this.set_name = params?.set_name ?? '';
		this.course_id = params?.course_id ? parseNonNegInt(params.course_id) : 0;
		const _set_visible = params?.set_visible ? parseBoolean(params?.set_visible) : false;
		this.set_visible = _set_visible ?? false;
		this.set_type = ProblemSetType.UNKNOWN;
		this.set_params = {};
		this.dates = {};
	}
}

export class Quiz extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.QUIZ;
		// parse the params
		const timed = params?.params.timed ? parseBoolean(params?.params.timed) : false;
		this.set_params = {
			timed: timed ?? false,
			quiz_duration: params?.params.quiz_duration ?
				parseNonNegInt(params?.params?.quiz_duration) :
				0
		};
		// parse the dates
		const _quiz_dates: QuizDates = {
			open: params?.params.open ? parseNonNegInt(params?.dates.open) : 0,
			due: params?.params.due ? parseNonNegInt(params?.dates.due) : 0,
			answer: params?.params.answer ? parseNonNegInt(params?.dates.answer) : 0,
		};
		this.dates = _quiz_dates;
	}
}

export class HomeworkSet extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.HW;
		// parse the params
		const rs = params?.params.enable_reduced_scoring ?
			parseBoolean(params?.params.enable_reduced_scoring) : false;
		const hh = params?.params.hide_hint ?
			parseBoolean(params?.params.hide_hint) : false;
		const _set_params: HomeworkSetParams = {
			enable_reduced_scoring: rs,
			hide_hint: hh,
			hardcopy_header: params?.params.hardcopy_header ?? '',
			set_header: params?.params.set_header ?? '',
			description: params?.params.description ?? '',
		};
		this.set_params = _set_params;
		// parse the dates
		const _hw_dates: HomeworkSetDates = {
			open: params?.params.open ? parseNonNegInt(params?.dates.open) : 0,
			reduced_scoring: params?.params.reduced_scoring ?
				parseNonNegInt(params?.dates.reduced_scoring) : 0,
			due: params?.params.due ? parseNonNegInt(params?.dates.due) : 0,
			answer: params?.params.answer ? parseNonNegInt(params?.dates.answer) : 0,
		};
		this.dates = _hw_dates;
	}
}

export class ReviewSet extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.REVIEW_SET;
		// parse the params

		// parse the dates
	}
}

export function parseProblemSet(set: ParseableProblemSet) {
	if (set.set_type == 'HW') {
		return new HomeworkSet(set);
	} else if (set.set_type == 'QUIZ') {
		return new Quiz(set);
	} else if (set.set_type === 'REVIEW') {
		return new ReviewSet(set);
	} else {
		throw `The problem set type '${set.set_type}' is not valid.'`;
	}
}

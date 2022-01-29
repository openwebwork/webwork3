import { RequiredFieldsException, Model, Dictionary, generic  } from 'src/common/models';
import { parseNonNegInt, parseBoolean, parseUsername } from './parsers';

export interface ParseableCourse {
	course_id?: number | string;
	course_name?: string;
	visible?: string | number | boolean;
	course_dates? : ParseableCourseDates;
}

export interface ParseableCourseDates {
	start?: string;
	end?: string;
}

class CourseDates extends Model {
	private _start = '';
	private _end = '';
	constructor(params: ParseableCourseDates = {}) {
		super();
		this.set(params);
	}

	get all_field_names(): string[] {
		return ['start', 'end'];
	}

	get param_fields(): string[] {
		return [];
	}

	set(params: ParseableCourseDates) {
		if (params.end != undefined) this.end = params.end;
		if (params.start != undefined) this.start = params.start;
	}

	get start() { return this._start; }
	set start(value: string) { this._start = value; }

	get end() { return this._end; }
	set end(value: string) { this._end = value; }
}

export class Course extends Model {
	private _course_id = 0;
	private _course_name = '';
	private _visible = true;
	private course_dates = new CourseDates();

	get all_field_names(): string[] {
		return ['course_id', 'course_name', 'visible', 'course_dates'];
	}

	get param_fields(): string[] {
		return ['course_dates'];
	}

	constructor(params: ParseableCourse = {}) {
		super();
		if (params.course_name == undefined) {
			throw new RequiredFieldsException('course_name');
		}
		this.set(params);
	}

	set(params: ParseableCourse) {
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.course_name != undefined) this.course_name = params.course_name;
		if (params.visible != undefined) this.visible = params.visible;
		super.checkParams(params as Dictionary<generic>);
	}

	setDates(date_params: ParseableCourseDates = {}) {
		this.course_dates.set(date_params as Dictionary<generic>);
	}

	get course_id() { return this._course_id; }
	set course_id(value: string | number) {
		this._course_id = parseNonNegInt(value);
	}

	get course_name() { return this._course_name; }
	set course_name(value: string) {
		this._course_name = value;
	}

	get visible() { return this._visible; }
	set visible(value: string | number | boolean) {
		this._visible = parseBoolean(value);
	}

}

/**
 * The class UserCourse is information about course that a user is in.
 */

export interface ParseableUserCourse {
	course_id?: number | string;
	user_id?: number | string;
	course_name?: string;
	username?: string;
	visible?: number | string | boolean;
	course_dates?: ParseableCourseDates;
}
export class UserCourse extends Model {
	private _course_id = 0;
	private _user_id = 0;
	private _course_name = '';
	private _username = '';
	private _visible = true;
	private course_dates = new CourseDates();

	static ALL_FIELDS = ['course_id', 'course_name', 'visible', 'course_dates', 'user_id', 'username'];

	get all_field_names(): string[] {
		return UserCourse.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['course_dates'];
	}

	constructor(params: ParseableCourse = {}) {
		super();
		if (params.course_name == undefined) {
			throw new RequiredFieldsException('course_name');
		}
		this.set(params);
	}

	set(params: ParseableCourse) {
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.course_name != undefined) this.course_name = params.course_name;
		if (params.visible != undefined) this.visible = params.visible;
		super.checkParams(params as Dictionary<generic>);
	}

	setDates(date_params: ParseableCourseDates = {}) {
		this.course_dates.set(date_params as Dictionary<generic>);
	}

	get course_id() { return this._course_id; }
	set course_id(value: string | number) {
		this._course_id = parseNonNegInt(value);
	}

	get user_id() { return this._user_id; }
	set user_id(value: string | number) {
		this._user_id = parseNonNegInt(value);
	}

	get username() { return this._username;}
	set username(value: string) {
		this._username = parseUsername(value);
	}

	get course_name() { return this._course_name; }
	set course_name(value: string) {
		this._course_name = value;
	}

	get visible() { return this._visible; }
	set visible(value: string | number | boolean) {
		this._visible = parseBoolean(value);
	}

}

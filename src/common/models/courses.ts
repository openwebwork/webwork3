import { RequiredFieldsException, Model, Dictionary, generic  } from 'src/common/models';
import { parseNonNegInt, parseBoolean, parseUsername, parseUserRole } from './parsers';

export interface ParseableCourse {
	course_id?: number | string;
	course_name?: string;
	visible?: string | number | boolean;
	course_dates? : ParseableCourseDates;
}

export interface ParseableCourseDates {
	start?: number | string;
	end?: number | string;
}

class CourseDates extends Model {
	private _start = 0; // start date in unix_time
	private _end = 0; // end date in unix_time
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
	set start(value: number | string) { this._start = parseNonNegInt(value); }

	get end() { return this._end; }
	set end(value: number | string) { this._end = parseNonNegInt(value); }
}

export class Course extends Model {
	private _course_id = 0;
	private _course_name = '';
	private _visible = true;
	private course_dates = new CourseDates();

	get all_field_names(): string[] {
		return Course.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['course_dates'];
	}

	static ALL_FIELDS = ['course_id', 'course_name', 'visible', 'course_dates'];

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

	get course_id(): number { return this._course_id; }
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

	clone() {
		return new Course(this.toObject() as ParseableCourse);
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
	role?: string;
	course_dates?: ParseableCourseDates;
}
export class UserCourse extends Model {
	private _course_id = 0;
	private _user_id = 0;
	private _course_name = '';
	private _username = '';
	private _visible = true;
	private _role = '';
	private course_dates = new CourseDates();

	static ALL_FIELDS = ['course_id', 'course_name', 'visible', 'course_dates',
		'user_id', 'username', 'role'];

	get all_field_names(): string[] {
		return UserCourse.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['course_dates'];
	}

	constructor(params: ParseableUserCourse = {}) {
		super();
		if (params.course_name == undefined) {
			throw new RequiredFieldsException('course_name');
		}
		if (params.username == undefined) {
			throw new RequiredFieldsException('username');
		}
		this.set(params);
	}

	set(params: ParseableUserCourse) {
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.course_name != undefined) this.course_name = params.course_name;
		if (params.visible != undefined) this.visible = params.visible;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.username != undefined) this.username = params.username;
		if (params.role != undefined) this.role = params.role;
		super.checkParams(params as Dictionary<generic>);
	}

	setDates(date_params: ParseableCourseDates = {}) {
		this.course_dates.set(date_params as Dictionary<generic>);
	}

	get course_id(): number { return this._course_id; }
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

	get role() { return this._role; }
	set role(value: string) { this._role = parseUserRole(value); }

}

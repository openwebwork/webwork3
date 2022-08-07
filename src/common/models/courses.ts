import { RequiredFieldsException, Model, Dictionary, generic  } from 'src/common/models';
import { UserRole } from 'src/stores/permissions';
import { isNonNegInt, isValidUsername } from './parsers';

export interface ParseableCourse {
	course_id?: number;
	course_name?: string;
	visible?: boolean;
	course_dates? : ParseableCourseDates;
}

export interface ParseableCourseDates {
	start?: number;
	end?: number;
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
	set start(value: number) { this._start = value; }

	get end() { return this._end; }
	set end(value: number) { this._end = value; }

	isValid(): boolean {
		return this.start <= this.end;
	}
}

export class Course extends Model {
	private _course_id = 0;
	private _course_name = '';
	private _visible = true;
	private _course_dates = new CourseDates();

	get all_field_names(): string[] {
		return Course.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['course_dates'];
	}

	get course_dates() { return this._course_dates; }

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
		if (params.course_dates) this.setDates(params.course_dates);
	}

	setDates(date_params: ParseableCourseDates = {}) {
		this.course_dates.set(date_params as Dictionary<generic>);
	}

	get course_id(): number { return this._course_id; }
	set course_id(value: number) { this._course_id = value; }

	get course_name() { return this._course_name; }
	set course_name(value: string) { this._course_name = value; }

	get visible() { return this._visible; }
	set visible(value: boolean) { this._visible = value; }

	clone() {
		return new Course(this.toObject() as ParseableCourse);
	}

	isValid(): boolean {
		return this.course_name.length > 0 && isNonNegInt(this.course_id) && this.course_dates.isValid();
	}
}

/**
 * The class UserCourse is information about course that a user is in.
 */

export interface ParseableUserCourse {
	course_id?: number;
	user_id?: number;
	course_name?: string;
	username?: string;
	visible?: boolean;
	role?: string;
	course_dates?: ParseableCourseDates;
}
export class UserCourse extends Model {
	private _course_id = 0;
	private _user_id = 0;
	private _course_name = '';
	private _username = '';
	private _visible = true;
	private _role = 'unknown';
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
		this.set(params);
	}

	set(params: ParseableUserCourse) {
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.course_name != undefined) this.course_name = params.course_name;
		if (params.visible != undefined) this.visible = params.visible;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.username) this.username = params.username;
		if (params.role) this.role = params.role;
	}

	setDates(date_params: ParseableCourseDates = {}) {
		this.course_dates.set(date_params as Dictionary<generic>);
	}

	get course_id(): number { return this._course_id; }
	set course_id(value: number) { this._course_id = value; }

	get user_id() { return this._user_id; }
	set user_id(value: number) { this._user_id = value;}

	get username() { return this._username;}
	set username(value: string) { this._username = value; }

	get course_name() { return this._course_name; }
	set course_name(value: string) { this._course_name = value; }

	get visible() { return this._visible; }
	set visible(value: boolean) { this._visible = value; }

	get role(): UserRole { return this._role; }
	set role(value: string) { this._role = value; }

	clone(): UserCourse {
		return new UserCourse(this.toObject());
	}

	isValid(): boolean {
		return isNonNegInt(this.course_id) && isNonNegInt(this.user_id) && isValidUsername(this.username)
			&& this.role !== 'unknown' && this.course_name.length > 0 && this.course_dates.isValid();
	}
}

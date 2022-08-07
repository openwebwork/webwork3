/* This file contains the definitions of a User, DBCourseUser and Course User
	in terms of a model. */

import { isNonNegInt, isValidUsername, isValidEmail }
	from 'src/common/models/parsers';
import { Dictionary, Model } from 'src/common/models';
import { UserRole } from 'src/stores/permissions';

export interface ParseableUser {
	user_id?: number;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: boolean;
	student_id?: string;
}

/**
 * @class User
 */
export class User extends Model {
	private _user_id = 0;
	private _username = '';
	private _is_admin = false;
	private _email = '';
	private _first_name = '';
	private _last_name = '';
	private _student_id = '';

	static ALL_FIELDS = ['user_id', 'username', 'is_admin', 'email', 'first_name',
		'last_name', 'student_id'];

	get all_field_names(): string[] { return User.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	constructor(params: ParseableUser = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableUser) {
		if (params.username) this.username = params.username;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.is_admin != undefined) this.is_admin = params.is_admin;
		if (params.email) this.email = params.email;
		if (params.first_name) this.first_name = params.first_name;
		if (params.last_name) this.last_name = params.last_name;
		if (params.student_id) this.student_id = params.student_id;
	}

	// otherwise, typescript identifies this as number | string
	get user_id(): number { return this._user_id; }
	set user_id(value: number) { this._user_id = value; }

	get username() { return this._username; }
	set username(value: string) { this._username = value; }

	get is_admin() { return this._is_admin; }
	set is_admin(value: boolean) { this._is_admin = value; }

	get email(): string { return this._email; }
	set email(value: string) { this._email = value; }

	get first_name(): string { return this._first_name; }
	set first_name(value: string) { this._first_name = value; }

	get last_name(): string { return this._last_name; }
	set last_name(value: string) { this._last_name = value; }

	get student_id(): string { return this._student_id; }
	set student_id(value: string) { this._student_id = value; }

	clone() {
		return new User(this.toObject() as ParseableUser);
	}

	// The email can be the empty string or valid email address.
	isValid(): boolean {
		return isNonNegInt(this.user_id) && isValidUsername(this.username) &&
			(this.email === '' || isValidEmail(this.email));
	}
}

export interface ParseableDBCourseUser {
	course_user_id?: number;
	user_id?: number;
	course_id?: number;
	role?: string;
	section?: string;
	recitation?: string;
}

/**
 * @class DBCourseUser
 *
 * This is a client-side version of the model of a course user from the database.
 */
export class DBCourseUser extends Model {
	private _course_user_id = 0;
	private _course_id = 0;
	private _user_id = 0;
	private _role: UserRole = '';
	private _section?: string;
	private _recitation?: string;

	static ALL_FIELDS = ['course_user_id', 'course_id', 'user_id', 'role', 'section', 'recitation'];

	get all_field_names(): string[] { return DBCourseUser.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	constructor(params: ParseableDBCourseUser = {}) {
		super();
		this.set(params);
	}
	set(params: ParseableDBCourseUser) {
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.role != undefined) this.role = params.role;
		if (params.section) this.section = params.section;
		if (params.recitation) this.recitation = params.recitation;
	}

	get course_user_id(): number { return this._course_user_id; }
	set course_user_id(value: number) { this._course_user_id = value; }

	get course_id(): number { return this._course_id; }
	set course_id(value: number) { this._course_id = value; }

	get user_id(): number { return this._user_id; }
	set user_id(value: number) { this._user_id = value; }

	get role(): string | undefined { return this._role; }
	set role(value: string | undefined) {
		if (value != undefined) this._role = value;
	}

	get section(): string | undefined { return this._section; }
	set section(value: string | undefined) { if (value != undefined) this._section = value; }

	get recitation(): string | undefined { return this._recitation; }
	set recitation(value: string | undefined) { if (value != undefined) this._recitation = value; }

	clone() {
		return new DBCourseUser(this.toObject() as ParseableDBCourseUser);
	}

	isValid(): boolean {
		return isNonNegInt(this.user_id) && isNonNegInt(this.course_user_id) &&
			isNonNegInt(this.course_id);
	}
}

export interface ParseableCourseUser {
	course_user_id?: number;
	user_id?: number;
	course_id?: number;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: boolean;
	student_id?: string;
	role?: string | UserRole;
	section?: string;
	recitation?: string;
}

/**
 * @class CourseUser
 *
 * This is a join between a User and a DBCourseUser. This is more useful on the client
 * side of webwork.
 */
export class CourseUser extends Model {
	private _course_user_id = 0;
	private _course_id = 0;
	private _user_id = 0;
	private _is_admin = false;
	private _username = '';
	private _email = '';
	private _first_name = '';
	private _last_name = '';
	private _student_id = '';
	private _role = 'UNKNOWN';
	private _section?: string;
	private _recitation?: string;

	static ALL_FIELDS = ['course_user_id', 'course_id', 'user_id', 'is_admin', 'username', 'email',
		'first_name', 'last_name', 'student_id', 'role', 'section', 'recitation'];

	get all_field_names(): string[] { return CourseUser.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	constructor(params: ParseableCourseUser = {}) {
		super();
		this.set(params);
	}
	set(params: ParseableCourseUser) {
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.is_admin != undefined) this.is_admin = params.is_admin;
		if (params.username) this.username = params.username;
		if (params.email) this.email = params.email;
		if (params.first_name) this.first_name = params.first_name;
		if (params.last_name) this.last_name = params.last_name;
		if (params.student_id) this.student_id = params.student_id;
		if (params.role) this.role = params.role;
		if (params.section) this.section = params.section;
		if (params.recitation) this.recitation = params.recitation;
	}

	get course_user_id(): number { return this._course_user_id; }
	set course_user_id(value: number) { this._course_user_id = value; }

	get course_id(): number { return this._course_id; }
	set course_id(value: number) { this._course_id = value; }

	get user_id(): number { return this._user_id; }
	set user_id(value: number) { this._user_id = value; }

	get username(): string { return this._username; }
	set username(value: string) { this._username = value; }

	get is_admin(): boolean { return this._is_admin; }
	set is_admin(value: boolean) { this._is_admin = value; }

	get email(): string { return this._email; }
	set email(value: string) { this._email = value; }

	get role(): string | undefined { return this._role; }
	set role(value: string | undefined) {
		if (value != undefined) this._role = value;
	}

	get section(): string | undefined { return this._section; }
	set section(value: string | undefined) { if (value != undefined) this._section = value; }

	get recitation(): string | undefined { return this._recitation; }
	set recitation(value: string | undefined) { if (value != undefined) this._recitation = value; }

	get first_name(): string { return this._first_name; }
	set first_name(value: string) { this._first_name = value; }

	get last_name(): string { return this._last_name; }
	set last_name(value: string) { this._last_name = value; }

	get student_id(): string { return this._student_id; }
	set student_id(value: string) { this._student_id = value; }

	clone() {
		return new CourseUser(this.toObject() as ParseableCourseUser);
	}

	// The email can be the empty string or valid email address.
	isValid(): boolean {
		return isNonNegInt(this.user_id) && isNonNegInt(this.course_user_id) &&
			isNonNegInt(this.course_id) && isValidUsername(this.username) &&
			this.role !== 'UNKNOWN' && (this.email === '' || isValidEmail(this.email));
	}

	validate(): Dictionary<string | boolean> {
		return {
			course_id: isNonNegInt(this.course_id) || 'The course_id must be a non negative integer.',
			course_user_id: isNonNegInt(this.course_user_id) || 'The course_user_id must be a non negative integer.',
			user_id: isNonNegInt(this.user_id) || 'The user_id must be a non negative integer.',
			username: isValidUsername(this.username) || 'The username must be valid.',
			email: (this.email === '' || isValidEmail(this.email)) || 'The email must be valid',
			role: this.role !== 'UNKNOWN' || 'The role is not valid.',
		};
	}
}

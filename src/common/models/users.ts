
import { parseNonNegInt, parseUsername, parseBoolean, parseEmail, parseUserRole,
	UserRole } from 'src/common/models/parsers';
import { RequiredFieldsException, Model } from 'src/common/models';

export interface ParseableUser {
	user_id?: number | string;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: string | number | boolean;
	student_id?: string | number;
}

/**
 * @class User
 */
export class User extends Model {
	private _user_id = 0;
	private _username = '';
	private _is_admin = false;
	private _email?: string;
	private _first_name?: string;
	private _last_name?: string;
	private _student_id?: string;

	static ALL_FIELDS = ['user_id', 'username', 'is_admin', 'email', 'first_name',
		'last_name', 'student_id'];

	get all_field_names(): string[] {
		return User.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return [];
	}

	constructor(params: ParseableUser = {}) {
		super();
		if (params.username == undefined) {
			throw new RequiredFieldsException('username');
		}
		this.set(params);
	}

	set(params: ParseableUser) {
		// Since the first three are required, only set if the field exists.
		if (params.username != undefined) this.username = params.username;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.is_admin != undefined) this.is_admin = params.is_admin;
		this.email = params.email;
		this.first_name = params.first_name;
		this.last_name = params.last_name;
		this.student_id = params.student_id;
	}

	get user_id() { return this._user_id; }
	set user_id(value: number | string) {
		this._user_id = parseNonNegInt(value);
	}

	get username() { return this._username; }
	set username(value: string) {
		this._username = parseUsername(value);
	}

	get is_admin() { return this._is_admin; }
	set is_admin(value: string | number | boolean) {
		this._is_admin = parseBoolean(value);
	}

	get email(): string | undefined { return this._email; }
	set email(value: string | undefined) {
		if (value != undefined) this._email = parseEmail(value);
	}

	get first_name(): string | undefined { return this._first_name; }
	set first_name(value: string | undefined) {
		if (value != undefined) this._first_name = value;
	}

	get last_name(): string | undefined { return this._last_name; }
	set last_name(value: string | undefined) {
		if (value != undefined) this._last_name = value;
	}

	get student_id(): string | undefined { return this._student_id; }
	set student_id(value: string | number | undefined) {
		if (value != undefined) this._student_id = `${value}`;
	}
}

export interface ParseableCourseUser {
	course_user_id?: number | string;
	user_id?: number | string;
	course_id?: number | string;
	role?: string;
	section?: string | number;
	recitation?: string | number;
}

/**
 * @class CourseUser
 */
export class CourseUser extends Model {
	private _course_user_id = 0;
	private _course_id?: number;
	private _user_id?: number;
	private _role?: UserRole;
	private _section?: string;
	private _recitation?: string;

	static ALL_FIELDS = ['course_user_id', 'course_id', 'user_id', 'role', 'section', 'recitation'];

	get all_field_names(): string[] {
		return CourseUser.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return [];
	}

	constructor(params: ParseableCourseUser = {}) {
		super();
		this.set(params);
	}
	set(params: ParseableCourseUser) {
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		this.user_id = params.user_id;
		this.course_id = params.course_id;
		this.role = params.role;
		this.section = params.section;
		this.recitation = params.recitation;
	}

	get course_user_id(): number { return this._course_user_id; }
	set course_user_id(value: string | number) {
		this._course_user_id = parseNonNegInt(value);
	}

	get course_id(): number | undefined { return this._course_id; }
	set course_id(value: string | number | undefined) {
		if (value != undefined) this._course_id = parseNonNegInt(value);
	}

	get user_id() { return this._user_id; }
	set user_id(value: number | string | undefined) {
		if (value != undefined) this._user_id = parseNonNegInt(value);
	}

	get role(): string | undefined { return this._role; }
	set role(value: string | undefined) {
		if (value != undefined) this._role = parseUserRole(value);
	}

	get section(): string | undefined { return this._section; }
	set section(value: string | number | undefined) {
		if (value != undefined) this._section = `${value}`;
	}

	get recitation(): string | undefined { return this._recitation; }
	set recitation(value: string | number | undefined) {
		if (value != undefined) this._recitation = `${value}`;
	}
}

export interface ParseableMergedUser {
	course_user_id?: number | string;
	user_id?: number | string;
	course_id?: number | string;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: boolean | number | string;
	student_id?: string;
	role?: string;
	section?: string | number;
	recitation?: string | number;
}

/**
 * @class MergedUser
 *
 * This is a join between a User and a CourseUser, which
 * is much more appropriate for the client side in the instructor
 */
export class MergedUser extends Model {
	private _course_user_id = 0;
	private _course_id = 0;
	private _user_id = 0;
	private _is_admin = false;
	private _username?: string;
	private _email?: string;
	private _first_name?: string;
	private _last_name?: string;
	private _student_id?: string;
	private _role?: UserRole;
	private _section?: string;
	private _recitation?: string;

	get all_field_names(): string[] {
		return ['course_user_id', 'course_id', 'user_id', 'is_admin', 'username', 'email',
			'first_name', 'last_name', 'student_id', 'role', 'section', 'recitation'];
	}

	get param_fields(): string[] {
		return [];
	}

	constructor(params: ParseableMergedUser = {}) {
		super();
		this.set(params);
	}
	set(params: ParseableMergedUser) {
		if (params.course_user_id != undefined) this.course_user_id = params.course_user_id;
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.user_id != undefined) this.user_id = params.user_id;
		if (params.is_admin != undefined) this.is_admin = params.is_admin;
		this.username = params.username;
		this.email = params.email;
		this.first_name = params.first_name;
		this.last_name = params.last_name;
		this.student_id = params.student_id;
		this.role = params.role;
		this.section = params.section;
		this.recitation = params.recitation;
	}

	get course_user_id(): number { return this._course_user_id; }
	set course_user_id(value: string | number) {
		this._course_user_id = parseNonNegInt(value);
	}

	get course_id(): number { return this._course_id; }
	set course_id(value: string | number) {
		this._course_id = parseNonNegInt(value);
	}

	get user_id() { return this._user_id; }
	set user_id(value: number | string) {
		this._user_id = parseNonNegInt(value);
	}

	get username() { return this._username; }
	set username(value: string | undefined) {
		if (value != undefined) this._username = parseUsername(value);
	}

	get is_admin() { return this._is_admin; }
	set is_admin(value: string | number | boolean | undefined) {
		if (value != undefined) this._is_admin = parseBoolean(value);
	}

	get email(): string | undefined { return this._email; }
	set email(value: string | undefined) {
		if (value != undefined) this._email = parseEmail(value);
	}

	get role(): string | undefined { return this._role; }
	set role(value: string | undefined) {
		if (value != undefined) this._role = parseUserRole(value);
	}

	get section(): string | undefined { return this._section; }
	set section(value: string | number | undefined) {
		if (value != undefined) this._section = `${value}`;
	}

	get recitation(): string | undefined { return this._recitation; }
	set recitation(value: string | number | undefined) {
		if (value != undefined) this._recitation = `${value}`;
	}

	get first_name(): string | undefined { return this._first_name; }
	set first_name(value: string | undefined) {
		if (value != undefined) this._first_name = value;
	}

	get last_name(): string | undefined { return this._last_name; }
	set last_name(value: string | undefined) {
		if (value != undefined) this._last_name = value;
	}

	get student_id(): string | undefined { return this._student_id; }
	set student_id(value: string | number | undefined) {
		if (value != undefined) this._student_id = `${value}`;
	}
}

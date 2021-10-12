// This is utility functions for users

import { Dictionary, parseBoolean, parseNonNegInt, parseEmail, parseUsername,
	ParseError, Model } from 'src/store/models/index';

import { isUndefined } from 'lodash';

export const user_roles = ['admin', 'instructor', 'TA', 'student'];

export function parseUserRole(role: string) {
	if (user_roles.findIndex((v) => v === role) < 0) {
		const err = new ParseError('InvalidRole', `The value '${role}' is not a valid role`);
		err.field = 'role';
		throw err;
	}
	return role;
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

export class User extends Model {
	user_id: number;
	username: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin: boolean;
	student_id?: string;

	static REQUIRED_FIELDS = ['username'];
	static OPTIONAL_FIELDS = ['user_id', 'email', 'first_name', 'last_name', 'is_admin', 'student_id'];

	get required_fields() {
		return (this._required_fields?.length==0) ? User.REQUIRED_FIELDS : [];
	}

	get all_fields() {
		return [...User.REQUIRED_FIELDS, ...User.OPTIONAL_FIELDS];
	}

	static get ALL_FIELDS() {
		return [...User.REQUIRED_FIELDS, ...User.OPTIONAL_FIELDS];
	}

	constructor(params: ParseableUser = {}){
		super(params as Dictionary<string|number|boolean>);
		this.user_id = 0;
		this.username = '';
		this.is_admin = false;
		this.set(params);
	}

	set(params: ParseableUser) {
		if (!isUndefined(params.user_id)) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (!isUndefined(params.username)) {
			this.username = parseUsername(params.username);
		}
		if (!isUndefined(params.email)) {
			this.email = parseEmail(params.email);
		}
		if (!isUndefined(params.first_name)) {
			this.first_name = params?.first_name;
		}
		if (!isUndefined(params.last_name)) {
			this.last_name = params?.last_name;
		}
		if (!isUndefined(params.is_admin)){
			this.is_admin = parseBoolean(params?.is_admin);
		}
		if (!isUndefined(params.student_id)) {
			this.student_id = params.student_id?.toString();
		}
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

export class CourseUser extends Model {
	course_user_id?: number;
	user_id: number;
	course_id?: number;
	role?: string;
	section?: string;
	recitation?: string;

	static REQUIRED_FIELDS = [];
	static OPTIONAL_FIELDS = ['course_user_id', 'user_id', 'course_id', 'role', 'section', 'recitation'];

	get required_fields() {
		return (this._required_fields?.length==0) ? CourseUser.REQUIRED_FIELDS : [];
	}

	get all_fields() {
		return [...CourseUser.REQUIRED_FIELDS, ...CourseUser.OPTIONAL_FIELDS];
	}

	static get ALL_FIELDS() {
		return [...CourseUser.REQUIRED_FIELDS, ...CourseUser.OPTIONAL_FIELDS];
	}

	constructor(params: ParseableCourseUser = {}) {
		super(params as Dictionary<string|number|boolean>);
		this.user_id = 0;
		this.set(params);
	}

	set(params: ParseableCourseUser = {}) {
		if (!isUndefined(params.course_user_id)) {
			this.course_user_id = parseNonNegInt(params.course_user_id);
		}
		if (!isUndefined(params.course_id)) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (!isUndefined(params.user_id)) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (!isUndefined(params.role)) {
			this.role = parseUserRole(params.role);
		}
		if (!isUndefined(params.section)) {
			this.section = `${params.section}`;
		}
		if (!isUndefined(params.recitation)) {
			this.recitation = `${params.recitation}`;
		}
	}
}

/* This is a join between a User and a CourseUser, which
is much more appropriate for the client side in the instructor */

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

export class MergedUser extends Model {
	course_user_id: number;
	user_id: number;
	course_id?: number;
	username: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin: boolean;
	student_id?: string;
	role?: string;
	section?: string;
	recitation?: string;

	static REQUIRED_FIELDS = ['username'];
	static OPTIONAL_FIELDS = [...User.OPTIONAL_FIELDS, ...CourseUser.OPTIONAL_FIELDS];

	get required_fields() {
		return (this._required_fields?.length==0) ? MergedUser.REQUIRED_FIELDS : [];
	}

	get all_fields() {
		return [...MergedUser.REQUIRED_FIELDS, ...MergedUser.OPTIONAL_FIELDS];
	}

	static get ALL_FIELDS() {
		return [...MergedUser.REQUIRED_FIELDS, ...MergedUser.OPTIONAL_FIELDS];
	}

	constructor(params: ParseableMergedUser = {}) {
		super(params as Dictionary<string|number|boolean>);
		this.course_user_id = 0;
		this.user_id = 0;
		this.username = '';
		this.is_admin = false;
		this.set(params);
	}

	set(params: ParseableMergedUser) {
		if (!isUndefined(params.user_id)) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (!isUndefined(params.username)) {
			this.username = parseUsername(params.username);
		}
		if (!isUndefined(params.email)) {
			this.email = parseEmail(params.email);
		}
		if (!isUndefined(params.first_name)) {
			this.first_name = params?.first_name;
		}
		if (!isUndefined(params.last_name)) {
			this.last_name = params?.last_name;
		}
		if (!isUndefined(params.is_admin)){
			this.is_admin = parseBoolean(params?.is_admin);
		}
		if (!isUndefined(params.student_id)) {
			this.student_id = params.student_id?.toString();
		}
		if (!isUndefined(params.course_user_id)) {
			this.course_user_id = parseNonNegInt(params.course_user_id);
		}
		if (!isUndefined(params.course_id)) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (!isUndefined(params.user_id)) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (!isUndefined(params.role)) {
			this.role = parseUserRole(params.role);
		}
		if (!isUndefined(params.section)) {
			this.section = `${params.section}`;
		}
		if (!isUndefined(params.recitation)) {
			this.recitation = `${params.recitation}`;
		}
	}
}

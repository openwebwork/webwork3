// This is utility functions for users

import { Dictionary, parseBoolean, parseNonNegInt, parseEmail, parseUsername,
	ParseError, Model } from '@/store/models/index';

// import { isUndefined, isNull } from 'lodash';

// function defined(_value: any) {
// return !isUndefined(_value) && !isNull(_value);
// }

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
		if (params.user_id != null) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (params.username != null) {
			this.username = parseUsername(params.username);
		}
		if (params.email != null) {
			this.email = parseEmail(params.email);
		}
		if (params.first_name != null) {
			this.first_name = params?.first_name;
		}
		if (params.last_name != null) {
			this.last_name = params?.last_name;
		}
		if (params.is_admin != null){
			this.is_admin = parseBoolean(params?.is_admin);
		}
		if (params.student_id != null) {
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
		if (params.course_user_id != null) {
			this.course_user_id = parseNonNegInt(params.course_user_id);
		}
		if (params.course_id != null) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (params.user_id != null) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (params.role != null) {
			this.role = parseUserRole(params.role);
		}
		if (params.section != null) {
			this.section = `${params.section}`;
		}
		if (params.recitation != null) {
			this.recitation = `${params.recitation}`;
		}
	}

	asObject(fields?: Array<string>) {
		const f = fields ?? this.all_fields;
		const obj: Dictionary<string|number|boolean|undefined> = {};
		if(f.indexOf('course_user_id')) { obj.course_user_id = this.course_user_id;}
		if(f.indexOf('user_id')) { obj.user_id = this.user_id; }
		if(f.indexOf('course_id')) { obj.course_id = this.course_id;}
		if(f.indexOf('role')) { obj.role = this.role; }
		if(f.indexOf('section')) { obj.section = this.section;}
		if(f.indexOf('course_id')) { obj.recitation = this.recitation;}
		return obj;
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
		if (params.user_id != null) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (params.username != null) {
			this.username = parseUsername(params.username);
		}
		if (params.email != null) {
			this.email = parseEmail(params.email);
		}
		if (params.first_name != null) {
			this.first_name = params.first_name;
		}
		if (params.last_name != null) {
			this.last_name = params.last_name;
		}
		if (params.is_admin != null){
			this.is_admin = parseBoolean(params.is_admin);
		}
		if (params.student_id != null) {
			this.student_id = params.student_id.toString();
		}
		if (params.course_user_id != null) {
			this.course_user_id = parseNonNegInt(params.course_user_id);
		}
		if (params.course_id != null) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (params.user_id != null) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (params.role != null) {
			this.role = parseUserRole(params.role);
		}
		if (params.section != null) {
			this.section = `${params.section}`;
		}
		if (params.recitation != null) {
			this.recitation = `${params.recitation}`;
		}
	}

	asObject(fields?: Array<string>) {
		const f = fields ?? this.all_fields;
		const obj: ParseableMergedUser = {};
		if(f.indexOf('username')>=0) { obj.username = this.username;}
		if(f.indexOf('email')>=0) { obj.email = this.email;}
		if(f.indexOf('first_name')>=0) { obj.first_name = this.first_name;}
		if(f.indexOf('last_name')>=0) { obj.last_name = this.last_name;}
		if(f.indexOf('is_admin')>=0) { obj.is_admin = this.is_admin;}
		if(f.indexOf('student_id')>=0) { obj.student_id = this.student_id;}
		if(f.indexOf('user_id')>=0) { obj.user_id = this.user_id; }
		if(f.indexOf('course_id')>=0) { obj.course_id = this.course_id;}
		if(f.indexOf('role')>=0) { obj.role = this.role; }
		if(f.indexOf('section')>=0) { obj.section = this.section;}
		if(f.indexOf('course_id')>=0) { obj.recitation = this.recitation;}
		return obj;
	}
}

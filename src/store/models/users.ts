// This is utility functions for users

import { intersection, isEqual, difference, assign, pick } from 'lodash';
import { Dictionary, parseBoolean, parseNonNegInt, parseEmail, parseUsername,
	mailRE, usernameRE, ParseError } from '@/store/models/index';

const required_user_params = ['username'];
export const user_roles = ['admin', 'instructor', 'TA', 'student'];

export function validUserRole(role: string) {
	if (user_roles.findIndex((v) => v === role) < 0) {
		throw {
			field: 'role',
			message: `The value '${role}' is not a valid role`,
		};
	}
	return true;
}

// function parseUser(params: ParseableUser): User {
// const user = new User();
// const user_fields = Object.keys(params);
// // check that the required fields are present in the params
// const common_fields = intersection(required_user_params, Object.keys(params));
// if (!isEqual(common_fields, required_user_params)) {
// const diff = difference(required_user_params, common_fields);
// throw {
// field: '_all',
// message: `The fields '${diff.join(', ')}' must be present in the user.`,
// params
// };
// }
// // validate the individual fields present
// Object.keys(params).forEach((key) => {
// if (user_fields.indexOf(key)<0) {
// throw {
// field: key,
// message: `The field '${key}' is not valid for a user`,
// params
// };
// }
// });
// validateUser(params);

// user.username = `${params.username || ''}` ;
// user.email = `${params.email || ''}`;
// user.first_name = `${params.first_name || ''}`;
// user.last_name = `${params.last_name || ''}`;
// user.student_id = `${params.student_id || ''}`;
// user.user_id = parseInt(`${params.user_id || ''}`) || 0;
// // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
// user.is_admin = parseBoolean(`${params.is_admin}`) || false;
// return user;
// }

export function validateUser(params: ParseableUser): boolean {
	if (params.email && !mailRE.test(`${params.email}`)) {
		throw {
			field: 'email',
			message: `The field '${params.email}' is not an email address`
		};
	}

	if (params.username && !(mailRE.test(`${params.username}`) || usernameRE.test(`${params.username}`))) {
		throw {
			field: 'username',
			message: `The field '${params.username}' is not a valid username`
		};
	}
	return true;
}

// export function parseMergedUser(_merged_user: ParseableMergedUser): MergedUser {
// const merged_user = newMergedUser();
// const course_user_params = pick(_merged_user, Object.keys(newCourseUser()));
// assign(merged_user, parseCourseUser(course_user_params));

// const user_params = pick(_merged_user, Object.keys(newUser()));
// assign(merged_user, parseUser(user_params));

// return merged_user;
// }

// export function parseCourseUser(_course_user: ParseableCourseUser): CourseUser {
// // const course_user = newCourseUser();
// const user_fields = Object.keys(_course_user);

// // check that the required fields are present in the params
// const common_fields = intersection(required_course_user_params, user_fields);
// if (!isEqual(common_fields, required_course_user_params)) {
// const diff = difference(required_course_user_params, common_fields);
// throw {
// message: `The field(s) '${diff.join(', ')}' must be present in the course user.`,
// field: undefined,
// course_user: _course_user
// };
// }
// Object.keys(_course_user).forEach((key) => {
// if (user_fields.indexOf(key)<0) {
// throw {
// field: key,
// message: `The field '${key}' is not valid for a course user`
// };
// }
// });
// validateCourseUser(_course_user);

// // need to find a more robust way to handle this.
// const course_user = new CourseUser();
// course_user.course_user_id = _course_user.course_user_id ? parseInt(`${_course_user.course_user_id}`) : 0 ;
// course_user.course_id = _course_user.course_id ? parseInt(`${_course_user.course_id}`) : 0 ;
// course_user.role = _course_user.role ? `${_course_user.role}` : '';
// course_user.section = _course_user.section ? `${_course_user.section}` : '';
// course_user.recitation = _course_user.recitation ? `${_course_user.recitation}` : '';

// return course_user;
// }

export interface ParseableUser {
	user_id?: number | string;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: string | number | boolean;
	student_id?: string | number;
}

export class RequiredFieldsException extends ParseError {
	constructor(_field: string, message: string,){
		super('RequiredFieldsException', message);
		super.field = _field;
	}
}

export class Model {
	_required_fields: Array<string> = [];
	_optional_fields?: Array<string> = [];

	get all_fields(): Array<string> {
		return [];
	}

	get required_fields() {
		return this._required_fields;
	}

	constructor(_params: Dictionary<number|string|boolean> = {}){
		// check that required fields are present
		const common_fields = intersection(this.required_fields, Object.keys(_params));
		if (!isEqual(common_fields, required_user_params)) {
			const diff = difference(required_user_params, common_fields);
			throw new RequiredFieldsException('_all',
				`The field(s) '${diff.join(', ')}' must be present in the user.`
			);
		}

	}

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
		if (params.user_id) {
			this.user_id = parseNonNegInt(params.user_id);
		}
		if (params.username) {
			this.username = parseUsername(params.username);
		}
		if (params.email) {
			this.email = parseEmail(params.email);
		}
		if (params.first_name) {
			this.first_name = params?.first_name;
		}
		if (params.last_name) {
			this.last_name = params?.last_name;
		}
		if (params.is_admin){
			this.is_admin = parseBoolean(params?.is_admin);
		}
		if (params.student_id) {
			this.student_id = params.student_id?.toString();
		}
	}
}

export interface ParseableCourseUser {
	course_user_id?: number;
	user_id?: number;
	course_id?: number;
	role?: string;
	section?: string;
	recitation?: string;
	params?: Dictionary<string>;
}

export class CourseUser {
	course_user_id?: number;
	user_id: number;
	course_id?: number;
	role?: string;
	section?: string;
	recitation?: string;
	params?: Dictionary<string>;

	constructor(params?: ParseableMergedUser) {
		this.course_user_id = params?.course_user_id ?? 0;
		this.course_id = params?.course_id ?? 0;
		this.user_id = params?.user_id ?? 0;
		this.role = params?.role ?? '';
		this.section = params?.section ?? '';
		this.recitation = params?.recitation ?? '';
		this.params = params?.params ?? {};
	}
}

/* This is a join between a User and a CourseUser, which
is much more appropriate for the client side in the instructor */

export interface ParseableMergedUser {
	course_user_id?: number;
	user_id?: number;
	course_id?: number;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: boolean;
	student_id?: string;
	role?: string;
	section?: string;
	recitation?: string;
	params?: Dictionary<string>;
}

export class MergedUser {
	course_user_id: number;
	user_id: number;
	course_id: number;
	username: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin: boolean;
	student_id: string;
	role: string;
	section: string;
	recitation: string;
	params: Dictionary<string>;

	constructor(params?: ParseableMergedUser) {
		this.course_user_id = params?.course_user_id ?? 0;
		this.course_id = params?.course_id ?? 0;
		this.user_id = params?.user_id ?? 0;
		this.username = params?.username ?? '';
		this.email = params?.email ?? '';
		this.first_name = params?.first_name ?? '';
		this.last_name = params?.last_name ?? '';
		this.is_admin = params?.is_admin ?? false;
		this.student_id = params?.student_id ?? '';
		this.role = params?.role ?? '';
		this.section = params?.section ?? '';
		this.recitation = params?.recitation ?? '';
		this.params = params?.params ?? {};
	}
}

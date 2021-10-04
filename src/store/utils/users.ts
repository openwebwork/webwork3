// This is utility functions for users

import { intersection, isEqual, difference } from 'lodash';
import { User, CourseUser, MergedUser, ParseableCourseUser,
	ParseableMergedUser, ParseableUser } from 'src/store/models';
import { mailRE, parseBoolean, usernameRE, user_roles } from './common';

const required_user_params = ['username'];

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: false,
		last_name: '',
		username: '',
		student_id: '',
		user_id: 0
	};
}

const required_course_user_params = ['role'];

export function newCourseUser(): CourseUser {
	return {
		course_user_id: 0,
		user_id: 0,
		course_id: 0,
		role: 'student',
		section: '',
		recitation: '',
		params: {}
	};
}

export function newMergedUser(): MergedUser {
	return {
		course_user_id: 0,
		user_id: 0,
		course_id: 0,
		email: '',
		username: '',
		first_name: '',
		last_name: '',
		is_admin: false,
		student_id: '',
		role: 'student',
		section: '',
		recitation: '',
		params: {}
	};
}

export function parseUser(params: ParseableUser): User {
	const user = newUser();
	const user_fields = Object.keys(user);
	// check that the required fields are present in the params
	const common_fields = intersection(required_user_params, Object.keys(params));
	if (!isEqual(common_fields, required_user_params)) {
		const diff = difference(required_user_params, common_fields);
		throw {
			field: '_all',
			message: `The fields '${diff.join(', ')}' must be present in the user.`,
			params
		};
	}
	// validate the individual fields present
	Object.keys(params).forEach((key) => {
		if (user_fields.indexOf(key)<0) {
			throw {
				field: key,
				message: `The field '${key}' is not valid for a user`,
				params
			};
		}
	});
	validateUser(params);

	user.username = `${params.username || ''}` ;
	user.email = `${params.email || ''}`;
	user.first_name = `${params.first_name || ''}`;
	user.last_name = `${params.last_name || ''}`;
	user.student_id = `${params.student_id || ''}`;
	user.user_id = parseInt(`${params.user_id || ''}`) || 0;

	return user;
}

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

export function parseMergedUser(_merged_user: ParseableMergedUser): MergedUser {
	const merged_user = newMergedUser();

	merged_user.username = _merged_user.username ?? '';
	merged_user.first_name = _merged_user.first_name ?? '';
	merged_user.last_name = _merged_user.last_name ?? '';
	merged_user.email = _merged_user.email ?? '';
	merged_user.user_id = _merged_user.user_id ? parseInt(`${_merged_user.user_id}`) : 0;
	merged_user.course_id = _merged_user.course_id ? parseInt(`${_merged_user.course_id}`) : 0;
	merged_user.course_user_id = _merged_user.course_user_id ? parseInt(`${_merged_user.course_user_id}`) : 0;
	merged_user.is_admin = _merged_user.is_admin ? (parseBoolean(_merged_user.is_admin) ?? false) : false;
	merged_user.role = _merged_user.role ?? 'student';
	merged_user.recitation = _merged_user.recitation ?? '';
	merged_user.section = _merged_user.section ?? '';
	return merged_user;
}

export function parseCourseUser(_course_user: ParseableCourseUser): CourseUser {
	const course_user = newCourseUser();
	const user_fields = Object.keys(course_user);

	// check that the required fields are present in the params
	const common_fields = intersection(required_course_user_params, Object.keys(_course_user));
	if (!isEqual(common_fields, required_course_user_params)) {
		const diff = difference(required_course_user_params, common_fields);
		throw {
			message: `The field(s) '${diff.join(', ')}' must be present in the course user.`,
			course_user: _course_user
		};
	}
	Object.keys(_course_user).forEach((key) => {
		if (user_fields.indexOf(key)<0) {
			throw {
				field: key,
				message: `The field '${key}' is not valid for a course user`
			};
		}
	});
	validateCourseUser(_course_user);

	// need to find a more robust way to handle this.

	course_user.course_user_id = _course_user.course_user_id ? parseInt(`${_course_user.course_user_id}`) : 0 ;
	course_user.course_id = _course_user.course_id ? parseInt(`${_course_user.course_id}`) : 0 ;
	course_user.role = _course_user.role ? `${_course_user.role}` : '';
	course_user.section = _course_user.section ? `${_course_user.section}` : '';
	course_user.recitation = _course_user.recitation ? `${_course_user.recitation}` : '';

	return course_user;
}

export function validateCourseUser(_course_user: ParseableCourseUser): boolean {
	if (user_roles.findIndex((v) => v === _course_user.role) < 0) {
		throw {
			field: 'role',
			message: `The value '${_course_user.role || ''}' is not a valid role`
		};
	}
	return true;
}

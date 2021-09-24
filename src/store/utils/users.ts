// This is utility functions for users

import { intersection, isEqual, difference } from 'lodash';
import { User, CourseUser, Dictionary, DetailedCourseUser } from 'src/store/models';
import { mailRE, usernameRE, user_roles } from './common';

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

export function newDetailedCourseUser(): DetailedCourseUser {
	return {
		course_user_id: 0,
		user_id: 0,
		course_id: 0,
		email: '',
		username: '',
		first_name: '',
		last_name: '',
		is_admin: false,
		role: 'student',
		section: '',
		recitation: '',
		params: {}
	};
}

export function parseUser(params: Dictionary<string|number>): User {
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

	user.username = `${params.username}` || '';
	user.email = `${params.email}` || '';
	user.first_name = `${params.first_name}` || '';
	user.last_name = `${params.last_name}` || '';
	user.student_id = `${params.student_id}` || '';

	return user;
}

export function validateUser(params: Dictionary<string|number>): boolean {
	if (!mailRE.test(`${params.email}`)) {
		throw {
			field: 'email',
			message: `The field '${params.email}' is not an email address`
		};
	}

	if (!(mailRE.test(`${params.username}`) || usernameRE.test(`${params.username}`))) {
		throw {
			field: 'username',
			message: `The field '${params.username}' is not a valid username`
		};
	}
	return true;
}

export function parseCourseUser(params: Dictionary<string|number>): CourseUser {
	const course_user = newCourseUser();
	const user_fields = Object.keys(course_user);
	// check that the required fields are present in the params
	const common_fields = intersection(required_course_user_params, Object.keys(params));
	if (!isEqual(common_fields, required_course_user_params)) {
		const diff = difference(required_user_params, common_fields);
		throw {
			message: `The fields '${diff.join(', ')}' must be present in the course user.`,
			params
		};
	}
	Object.keys(params).forEach((key) => {
		if (user_fields.indexOf(key)<0) {
			throw {
				field: key,
				message: `The field '${key}' is not valid for a course user`
			};
		}
	});
	validateCourseUser(params);

	course_user.user_id = parseInt(`${params.user_id}`) || 0;
	course_user.role = `${params.role}` || '';
	course_user.section = `${params.section}` || '';
	course_user.recitation = `${params.recitation}` || '';

	return course_user;
}

export function validateCourseUser(params: Dictionary<string|number>): boolean {

	if (user_roles.findIndex((v) => v === params.role) < 0) {
		throw {
			field: 'role',
			message: `The value '${params.role}' is not a valid role`
		};
	}
	return true;
}

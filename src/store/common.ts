import { User, Course } from './models';

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: false,
		last_name: '',
		login: '',
		student_id: '',
		user_id: undefined
	};
}

export function newCourse(): Course {
	return {
		course_id: 0,
		course_name: '',
		visible: false,
		course_dates: {
			end: '',
			start: ''
		}
	}
}
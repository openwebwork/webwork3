import { User, Course, CourseUser, ProblemSet, ProblemSetType } from './models';

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: false,
		last_name: '',
		username: '',
		student_id: '',
		user_id: undefined
	};
}

export function newCourseUser(): CourseUser {
	return {
		course_user_id: 0,
		course_id: 0,
		role: 'student',
		section: '',
		recitation: '',
		params: {}
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
	};
}

export function newProblemSet(): ProblemSet {
	return {
		set_id: 0,
		set_name: '',
		course_id: 0,
		set_type: ProblemSetType.HW,
		set_visible: false,
		params: {},
		dates: {}
	};
}

import { Course, CourseUser, CourseSetting } from './models';

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

export function newCourseSetting(): CourseSetting {
	return {
		var: '',
		value: ''
	};
}

// This file contains common functionality for courses.

import { Course } from '../models';

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

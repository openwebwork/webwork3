// this has common utility functions for CourseSettings

import { CourseSetting } from '../models';

export function newCourseSetting(): CourseSetting {
	return {
		var: '',
		value: ''
	};
}

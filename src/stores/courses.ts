import { api } from 'boot/axios';
import { defineStore } from 'pinia';
import { logger } from 'src/boot/logger';
import { ResponseError } from 'src/common/api-requests/interfaces';

import { Course, ParseableCourse } from 'src/common/models/courses';

export interface CourseState {
	courses: Array<Course>;
}

export const useCourseStore = defineStore('courses', {
	state: (): CourseState => ({
		courses: []
	}),
	getters: {
		findCourse: (state) => (course_info: { course_id?: number; course_name?: string }) => {
			if (course_info.course_id) {
				return state.courses.find(course => course.course_id === course_info.course_id);
			} else if (course_info.course_name) {
				return state.courses.find(course => course.course_name === course_info.course_name);
			}
		},
		getCourseByName: (state) => {
			return (courseName: string) => state.courses.find((course) => course.course_name === courseName);
		}
	},
	actions: {
		async fetchCourses() : Promise<void> {
			const response = await api.get('courses');
			this.courses = (response.data as ParseableCourse[]).map(course => new Course(course));
		},
		async addCourse(course: Course): Promise<Course | undefined> {
			const response = await api.post('courses', course.toObject());
			if (response.status === 200) {
				const new_course = new Course(response.data as ParseableCourse);
				this.courses.push(new_course);
				return new_course;
			} else {
				logger.error(`[CourseStore/addCourse] ${JSON.stringify(response)}`);
				throw response.data as ResponseError;
			}
		}
	}
});

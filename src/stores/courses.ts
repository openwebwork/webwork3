import { api } from 'boot/axios';
import { defineStore } from 'pinia';
import { logger } from 'src/boot/logger';
import { invalidError, ResponseError } from 'src/common/api-requests/errors';

import { Course, ParseableCourse } from 'src/common/models/courses';

export interface CourseState {
	courses: Array<Course>;
}

type CourseInfo =
	{ course_id: number; course_name?: never } |
	{ course_name: string; course_id?: never };

export const useCourseStore = defineStore('courses', {
	state: (): CourseState => ({
		courses: []
	}),
	getters: {

		/**
		 * Returns a course in the store based on passing in either the course_id or course_name.
		 */
		findCourse: (state) => (course_info: CourseInfo) => {
			if (course_info.course_id) {
				return state.courses.find(course => course.course_id === course_info.course_id);
			} else if (course_info.course_name) {
				return state.courses.find(course => course.course_name === course_info.course_name);
			}
		}
	},
	actions: {

		/**
		 * Fetches all courses from the database with the results stored in the store.
		 */
		async fetchCourses() : Promise<void> {
			const response = await api.get('courses');
			this.courses = (response.data as ParseableCourse[]).map(course => new Course(course));
		},

		/**
		 * Adds a course to the database and the store.
		 */
		async addCourse(course: Course): Promise<Course | undefined> {
			if (!course.isValid()) await invalidError(course, 'The added course is invalid');

			const response = await api.post('courses', course.toObject());
			if (response.status === 200) {
				const new_course = new Course(response.data as ParseableCourse);
				this.courses.push(new_course);
				return new_course;
			} else {
				logger.error(`[CourseStore/addCourse] ${JSON.stringify(response)}`);
				throw response.data as ResponseError;
			}
		},

		/**
		 * This updates the course in the database and the store.
		 */
		async updateCourse(course: Course): Promise<Course | undefined> {
			if (!course.isValid()) await invalidError(course, 'The updated course is invalid');

			const response = await api.put(`courses/${course.course_id}`, course.toObject());
			if (response.status === 200) {
				const updated_course = new Course(response.data as ParseableCourse);
				const index = this.courses.findIndex(course => course.course_id === updated_course.course_id);
				this.courses.splice(index, 1, updated_course);
				return updated_course;
			} else {
				throw response.data as ResponseError;
			}
		},

		/**
		 * This deletes the course in the database and the store.
		 */
		async deleteCourse(course: Course): Promise<void> {
			const response = await api.delete(`courses/${course.course_id}`);
			if (response.status === 200) {
				const index = this.courses.findIndex(c => c.course_id === course.course_id);
				this.courses.splice(index, 1);
			} else {
				throw response.data as ResponseError;
			}
		}
	}
});

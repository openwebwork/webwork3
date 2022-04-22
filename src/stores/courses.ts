import { api } from 'boot/axios';
import { defineStore } from 'pinia';
import { logger } from 'src/boot/logger';
import { ResponseError } from 'src/common/api-requests/interfaces';

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
		 * returns a course in the store.
		 * @param {CourseInfo} course_info - either a course_id or course_name
		 * @returns {Course} the requested course
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
		 * fetches all courses from the database with the results stored in the store.
		 */
		async fetchCourses() : Promise<void> {
			const response = await api.get('courses');
			this.courses = (response.data as ParseableCourse[]).map(course => new Course(course));
		},
		/**
		 * Adds a course to the database and the store.
		 * @param {Course} course - the course to be added.
		 * @return {Course} the added course.
		 */
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
		},
		/**
		 * This updates the course in the database and the store.
		 * @param {Course} course - the course to be updated.
		 * @return {Course} the updated course.
		 */
		async updateCourse(course: Course): Promise<Course | undefined> {
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
		 * @param {Course} course - the course to be deleted.
		 * @return {Course} the deleted course.
		 */
		async deleteCourse(course: Course): Promise<Course | undefined> {
			const response = await api.delete(`courses/${course.course_id}`);
			if (response.status === 200) {
				const deleted_course = new Course(response.data as ParseableCourse);
				const index = this.courses.findIndex(course => course.course_id === deleted_course.course_id);
				this.courses.splice(index, 1);
				return deleted_course;
			} else {
				throw response.data as ResponseError;
			}
		}
	}
});

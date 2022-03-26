import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { Course, ParseableCourse } from 'src/common/models/courses';

export interface CourseState {
	courses: Array<Course>;
}

export const useCourseStore = defineStore('courses', {
	state: (): CourseState => ({
		courses: []
	}),
	getters: { },
	actions: {
		async fetchCourses() : Promise<void> {
			const response = await api.get('courses');
			this.courses = (response.data as ParseableCourse[]).map(course => new Course(course));
		},
		async addCourse(course: Course): Promise<Course> {
			const response = await api.post('courses', course);
			const new_course = new Course(response.data as ParseableCourse);
			this.courses.push(new_course);
			return new_course;
		}
	}
});

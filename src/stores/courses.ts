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
	getters: {
		findCourse: (state) => (course_info: { course_id?: number; course_name?: string }) => {
			if (course_info.course_id) {
				return state.courses.find(course => course.course_id === course_info.course_id);
			} else if (course_info.course_name) {
				return state.courses.find(course => course.course_name === course_info.course_name);
			}
		}

	},
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

import axios from 'axios';
import { Commit } from 'vuex';

import { Course } from '../models';

export interface CourseState {
	courses: Array<Course>;
}

const initial_state = {
	courses: []
};

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		courses(state: CourseState): Array<Course> {
			return state.courses;
		}
	},
	actions: {
		async fetchCourses({ commit }: { commit: Commit }): Promise<void> {
			const response = await axios.get('/webwork3/api/courses');
			commit('SET_COURSES', response.data as Array<Course>);
		},
		async addCourse({ commit }: { commit: Commit}, _course: Course): Promise<Course> {
			const response = await axios.post('/webwork3/api/courses', _course);
			const course = response.data as Course;
			commit('ADD_COURSE', course);
			return course;
		}
	},
	mutations: {
		SET_COURSES(state: CourseState, _courses: Array<Course>): void {
			state.courses = _courses;
		},
		ADD_COURSE(state: CourseState, _course: Course): void {
			state.courses.push(_course);
		}
	}
};

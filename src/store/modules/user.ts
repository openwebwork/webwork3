import { User, Course } from "../models";
import { Commit } from 'vuex';

import { fetchUserCourses } from "../api";

interface State {
	users: Array<User>;
	user_courses: Array<Course>;
}

const initial_state = {
	users: [],
	user_courses: []
}

export const userModule = {
  namespaced: true,
  state: initial_state,
	getters: {
		user_courses(state: State): Array<Course> {
			return state.user_courses
		}
	},
  actions: {
		fetchUserCourses({ commit }: { commit: Commit },user_id: number): void {
			commit('fetchUserCourses',user_id);
		}
	},
  mutations: {
		async fetchUserCourses(state: State, user_id: number): Promise<void> {
			state.user_courses = await fetchUserCourses(user_id);
		}
	}
};
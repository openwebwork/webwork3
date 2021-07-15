import { Commit } from 'vuex';
// import { StateInterface } from '../index';

import { User, UserCourse } from '../models';

import axios from 'axios';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
}

const initial_state = {
	users: [],
	user_courses: []
}

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		user_courses(state: UserState): Array<UserCourse> {
			return state.user_courses
		}
	},
  actions: {
		async fetchUserCourses({ commit }: { commit: Commit },user_id: number): Promise<void> {
			const _user_courses = await _fetchUserCourses(user_id);
			commit('STORE_USER_COURSES',_user_courses);
		}
	},
  mutations: {
		STORE_USER_COURSES(state: UserState, _user_courses: Array<UserCourse>): void {
			state.user_courses = _user_courses;
		}
	}
};

async function _fetchUserCourses(user_id: number): Promise<Array<UserCourse>> {
	const response = await axios.get(`/webwork3/api/users/${user_id}/courses`);
	// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
	if (response.data.exception){
		return []
	} else {
		return response.data as Array<UserCourse>;
	}
}

import axios from 'axios';
import { Commit } from 'vuex';
import { StateInterface } from '../index';

import { User, UserCourse } from '../models';

interface APIError {
	exception: string;
	message: string;
}


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
		},
		async fetchUsers({ commit }: { commit: Commit },course_id: number): Promise<void> {
			const _users = await _fetchUsers(course_id);
			commit('SET_USERS',_users);
		},
		async addUser( { commit, rootState }: { commit: Commit, rootState: StateInterface}, _user: User): Promise<void> {
			const user = await _addUser(rootState.session.course.course_id,_user).catch( (err) => {
				throw(err);
			})
			commit('ADD_USER',user);
		}
	},
  mutations: {
		STORE_USER_COURSES(state: UserState, _user_courses: Array<UserCourse>): void {
			state.user_courses = _user_courses;
		},
		SET_USERS(state: UserState, _users: Array<User>): void {
			state.users = _users;
		},
		ADD_USER(state: UserState, _user: User): void {
			state.users.push(_user);
		}
	}
};

async function _fetchUserCourses(user_id: number): Promise<Array<UserCourse>> {
	const response = await axios.get(`/webwork3/api/users/${user_id}/courses`);
	// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
	return (response.data.exception) ? [] : (response.data as Array<UserCourse>);
}

async function _fetchUsers(course_id: number): Promise<Array<User>> {
	const response = await axios.get(`/webwork3/api/courses/${course_id}/users`);
	// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
	return (response.data.exception) ? [] : (response.data as Array<User>);
}

async function _addUser(course_id: number, _user: User): Promise<User|undefined> {

	const response = await axios.post(`/webwork3/api/courses/${course_id}/users`,_user);
	if (response.status === 200) {
		return response.data as User;
	} else if (response.status === 400) {
		throw(response.data as APIError)
	}
}
import axios from 'axios';
import { Commit, ActionContext } from 'vuex';
import { StateInterface } from '../index';

import { User, UserCourse, CourseUser, ResponseError } from '../models';

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
		async getUser( _context: ActionContext<UserState,StateInterface>, _login: string): Promise<User|undefined> {
			const response = await axios.get(`/webwork3/api/users/${_login}`);
			// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
			if (response.data.login && response.data.login !== '') {
				return response.data as User
			} else {
				return undefined;
			}
		},
		async addCourseUser( { commit, rootState }: { commit: Commit, rootState: StateInterface}, _course_user: CourseUser): Promise<CourseUser|undefined> {
			const course_id = rootState.session.course.course_id > 0 ?
				rootState.session.course.course_id :
				_course_user.course_id;
			const response = await axios.post(`/webwork3/api/courses/${course_id}/users`,_course_user);
			if (response.status === 200) {
				const u = response.data as CourseUser;
				commit('ADD_USER',u);
				return u;
			} else if (response.status === 400) {
				throw(response.data as ResponseError);
			}
		},
		async deleteUser( { commit,rootState }: { commit: Commit, rootState: StateInterface}, _user: User): Promise<User|undefined> {
			const course_id = rootState.session.course.course_id;
			const response = await axios.delete(`/webwork3/api/courses/${course_id}/users/${_user.user_id || 0}`);
			if (response.status === 200) {
				commit('DELETE_USER',_user);
				return response.data as User;
			} else if (response.status === 400) {
				throw(response.data as ResponseError);
			}
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
		},
		DELETE_USER(state: UserState, _user: User): void {
			const index =  state.users.findIndex( (u) => u.user_id === _user.user_id);
			state.users.splice(index,1);
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

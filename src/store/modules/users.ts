import { api } from 'boot/axios';
import type { Commit, ActionContext } from 'vuex';
import type { StateInterface } from '../index';

import { User, UserCourse, CourseUser, ResponseError } from '../models';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
}

export default {
	namespaced: true,
	state: {
		users: [],
		course_users: [],
		user_courses: []
	},
	getters: {
		user_courses(state: UserState): Array<UserCourse> {
			return state.user_courses;
		},
		users(state: UserState): Array<User> {
			return state.users;
		}
	},
	actions: {
		async fetchUsers({ commit }: {commit: Commit }): Promise<Array<User>|ResponseError> {
			const response = await api.get('users');
			if (response.status === 200) {
				const users = response.data as Array<User>;
				commit('SET_USERS', users);
				return users;
			} else {
				return response.data as ResponseError;
			}
		},
		async fetchUserCourses({ commit }: { commit: Commit }, user_id: number):
			Promise<Array<UserCourse>|ResponseError|undefined> {
			const response = await api.get(`users/${user_id}/courses`);
			if (response.status === 200) {
				const user_courses = response.data as Array<UserCourse>;
				commit('SET_USER_COURSES', user_courses);
			} else if (response.status === 250) {
				return response.data as ResponseError;
			}
		},
		async fetchCourseUsers({ commit }: { commit: Commit }, course_id: number):
			Promise<Array<CourseUser>|ResponseError|undefined> {
			const response = await api.get(`courses/${course_id}/users`);
			if (response.status === 200) {
				const course_users = response.data as Array<CourseUser>;
				commit('SET_COURSE_USERS', course_users);
				return course_users;
			} else if (response.status === 250) {
				return response.data as ResponseError;
			}
		},
		async getUser(
			_context: ActionContext<UserState, StateInterface>,
			_username: string): Promise<User | undefined> {
			const response = await api.get(`users/${_username}`);
			// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
			if (response.data.username && response.data.username !== '') {
				return response.data as User;
			} else {
				return undefined;
			}
		},
		async addUser({ commit }: { commit: Commit }, _user: User): Promise<User |undefined> {
			const response = await api.post('users', _user);
			if (response.status === 200) {
				const u = response.data as User;
				commit('ADD_USER', u);
				return u;
			} else if (response.status === 400) {
				throw response.data as ResponseError;
			}
		},
		async addCourseUser(
			{ commit, rootState }: { commit: Commit; rootState: StateInterface },
			_course_user: CourseUser
		): Promise<CourseUser | undefined> {
			const course_id =
				rootState.session.course.course_id > 0 ? rootState.session.course.course_id : _course_user.course_id;
			const response = await api.post(`courses/${course_id}/users`, _course_user);
			if (response.status === 200) {
				const u = response.data as CourseUser;
				commit('ADD_COURSE_USER', u);
				return u;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		async deleteCourseUser({ commit, rootState }: { commit: Commit; rootState: StateInterface },
			_course_user: CourseUser) {
			const course_id = rootState.session.course.course_id;
			const response = await api.delete(`courses/${course_id}/users/${_course_user.user_id || 0}`);
			if (response.status === 200) {
				commit('DELETE_COURSE_USER', _course_user);
				return response.data as User;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		async deleteUser({ commit }: { commit: Commit}, _user: User): Promise<User | undefined> {
			const response = await api.delete(`/users/${_user.user_id || 0}`);
			if (response.status === 200) {
				commit('DELETE_USER', _user);
				return response.data as User;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		}
	},
	mutations: {
		SET_USER_COURSES(state: UserState, _user_courses: Array<UserCourse>): void {
			state.user_courses = _user_courses;
		},
		SET_USERS(state: UserState, _users: Array<User>): void {
			state.users = _users;
		},
		ADD_USER(state: UserState, _user: User): void {
			state.users.push(_user);
		},
		DELETE_USER(state: UserState, _user: User): void {
			const index = state.users.findIndex((u) => u.user_id === _user.user_id);
			state.users.splice(index, 1);
		},
		SET_COURSE_USERS(state: UserState, _users: Array<CourseUser>): void {
			state.course_users = _users;
		},
		ADD_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			state.course_users.push(_course_user);
		},
		DELETE_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			const index = state.course_users.findIndex((u) => u.course_user_id ===_course_user.course_user_id);
			state.course_users.splice(index, 1);
		}
	}
};

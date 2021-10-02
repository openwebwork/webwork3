import { api } from 'boot/axios';
import type { Commit, ActionContext } from 'vuex';
import type { StateInterface } from 'src/store/index';
import { remove } from 'lodash-es';

import { User, UserCourse, CourseUser, ParseableCourseUser,
	MergedCourseUser, ParseableUser, ResponseError } from 'src/store/models';

import { parseCourseUser, parseUser } from 'src/store/utils/users';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
	merged_course_users: Array<MergedCourseUser>;
}

export default {
	namespaced: true,
	state: {
		users: [],
		course_users: [],
		merged_course_users: [],
		user_courses: []
	},
	getters: {
		user_courses(state: UserState): Array<UserCourse> {
			return state.user_courses;
		},
		users(state: UserState): Array<User> {
			return state.users;
		},
		merged_course_users(state: UserState): Array<MergedCourseUser> {
			return state.merged_course_users;
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
				const _course_users = response.data as Array<ParseableCourseUser>;
				const course_users = _course_users.map(parseCourseUser);

				commit('SET_COURSE_USERS', course_users);
				return course_users;
			} else if (response.status === 250) {
				return response.data as ResponseError;
			}
		},

		async fetchMergedCourseUsers({ commit }: { commit: Commit }, course_id: number):
			Promise<Array<MergedCourseUser>|ResponseError|undefined> {
			const response = await api.get(`courses/${course_id}/courseusers`);
			if (response.status === 200) {
				const _merged_course_users = response.data as Array<ParseableCourseUser>;
				const merged_course_users = _merged_course_users.map(parseCourseUser);

				commit('SET_MERGED_COURSE_USERS', merged_course_users);
				return merged_course_users;
			} else if (response.status === 250) {
				return response.data as ResponseError;
			}
		},
		async getUser(
			_context: ActionContext<UserState, StateInterface>,
			_username: string): Promise<ParseableUser | undefined> {
			const response = await api.get(`users/${_username}`);
			console.log(response);
			if (response.status === 200) {
				return response.data as ParseableUser;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		async addUser({ commit }: { commit: Commit }, _user: User): Promise<User |undefined> {
			const response = await api.post('users', _user);
			if (response.status === 200) {
				const u = response.data as ParseableUser;
				commit('ADD_USER', u);
				return parseUser(u);
			} else if (response.status === 400) {
				throw response.data as ResponseError;
			}
		},
		async addCourseUser({ rootState }: { rootState: StateInterface },
			_course_user: CourseUser): Promise<CourseUser | undefined> {
			const course_id =
				rootState.session.course.course_id > 0 ? rootState.session.course.course_id : _course_user.course_id;
			const response = await api.post(`courses/${course_id}/users`, _course_user);
			if (response.status === 200) {
				const u = response.data as CourseUser;
				// commit('ADD_COURSE_USER', u);
				return parseCourseUser(u);
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		addMergedCourseUser({ commit }: { commit: Commit }, _merged_course_user: MergedCourseUser): void {
			commit('ADD_MERGED_COURSE_USER', _merged_course_user);
		},
		deleteMergedCourseUser({ commit }: { commit: Commit }, _merged_course_user: MergedCourseUser): void {
			commit('DELETE_MERGED_COURSE_USER', _merged_course_user);
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
		SET_MERGED_COURSE_USERS(state: UserState, _merged_course_users: Array<MergedCourseUser>): void {
			state.merged_course_users = _merged_course_users;
		},
		SET_COURSE_USERS(state: UserState, _course_users: Array<CourseUser>): void {
			state.course_users = _course_users;
		},
		ADD_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			state.course_users.push(_course_user);
		},
		ADD_MERGED_COURSE_USER(state: UserState, _merged_course_user: MergedCourseUser): void {
			state.merged_course_users.push(_merged_course_user);
		},
		DELETE_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			const index = state.course_users.findIndex((u) => u.course_user_id ===_course_user.course_user_id);
			state.course_users.splice(index, 1);
		},
		DELETE_MERGED_COURSE_USER(state: UserState, _merged_course_user: MergedCourseUser): void {
			console.log(_merged_course_user);
			console.log(state.merged_course_users);
			const s = remove(state.merged_course_users, (u) => u.course_user_id === _merged_course_user.course_user_id);
			console.log(s);
			// const index = state.merged_course_users.findIndex(
			// (u) => );
			// state.merged_course_users.splice(index, 1);
		}
	}
};

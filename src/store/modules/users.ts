import { api } from 'boot/axios';

import type { Commit, ActionContext } from 'vuex';
import type { StateInterface } from 'src/store/index';

import { logger } from 'boot/logger';
import type { ParseableCourseUser, ParseableMergedUser, ParseableUser } from 'src/store/models/users';
import { User, MergedUser, CourseUser } from 'src/store/models/users';
import { ResponseError } from 'src/store/models';
import { UserCourse } from 'src/store/models/courses';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
	merged_users: Array<MergedUser>;
}

export default {
	namespaced: true,
	state: {
		users: [],
		course_users: [],
		merged_users: [],
		user_courses: [],
		set_users: []
	},
	getters: {
		user_courses(state: UserState): Array<UserCourse> {
			return state.user_courses;
		},
		users(state: UserState): Array<User> {
			return state.users;
		},
		merged_users(state: UserState): Array<MergedUser> {
			return state. merged_users;
		}
	},
	actions: {
		async fetchUsers({ commit }: {commit: Commit }): Promise<Array<User> | ResponseError> {
			const response = await api.get('users');
			if (response.status === 200) {
				const users = response.data as Array<User>;
				commit('SET_USERS', users);
				return users;
			} else {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async fetchUserCourses({ commit }: { commit: Commit }, user_id: number):
			Promise<Array<UserCourse> | ResponseError | undefined> {
			const response = await api.get(`users/${user_id}/courses`);
			if (response.status === 200) {
				const user_courses = response.data as Array<UserCourse>;
				commit('SET_USER_COURSES', user_courses);
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async fetchCourseUsers({ commit }: { commit: Commit }, course_id: number):
		Promise<Array<CourseUser> | ResponseError | undefined> {
			const response = await api.get(`courses/${course_id}/users`);
			if (response.status === 200) {
				const _course_users = response.data as Array<ParseableCourseUser>;
				const course_users = _course_users.map(u => new CourseUser(u));

				commit('SET_COURSE_USERS', course_users);
				return course_users;
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async fetchMergedUsers({ commit }: { commit: Commit }, course_id: number):
		Promise<Array<MergedUser> | ResponseError | undefined> {
			const response = await api.get(`courses/${course_id}/courseusers`);
			if (response.status === 200) {
				const _merged_users = response.data as Array<ParseableMergedUser>;
				const merged_users = _merged_users.map(u => new MergedUser(u));

				commit('SET_MERGED_USERS', merged_users);
				return merged_users;
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async getUser(_context: ActionContext<UserState, StateInterface>,
			_username: string): Promise<ParseableUser | undefined> {
			const response = await api.get(`users/${_username}`);
			if (response.status === 200) {
				return response.data as ParseableUser;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		async addUser({ commit }: { commit: Commit }, _user: User): Promise<User | undefined> {
			const u = await addUser(_user) as User;
			if (u) {
				commit('ADD_USER', u);
			}
			return u;
		},
		async addCourseUser(_context: ActionContext<UserState, StateInterface>,
			_course_user: CourseUser): Promise<CourseUser | undefined> {
			return await addCourseUser(_course_user);
		},
		async addMergedUser({ commit }: { commit: Commit }, _merged_user: MergedUser): Promise<MergedUser> {
			if (_merged_user.user_id === 0) { // this is a new user
				const _user = await addUser(_merged_user as User) as User;
				_merged_user.user_id = _user.user_id;
				_merged_user.username = _user.username;
			}
			const f = CourseUser.ALL_FIELDS;
			const _course_user = _merged_user.toObject(f) as unknown as CourseUser;
			const cu = await addCourseUser(_course_user);
			const merged_user = Object.assign(_merged_user, cu, _course_user) as MergedUser;
			commit('ADD_MERGED_USER', merged_user);
			return merged_user;
		},
		async updateCourseUser(_context: ActionContext<UserState, StateInterface>, _course_user: CourseUser)
			: Promise<CourseUser | undefined> {
			const url = `courses/${_course_user.course_id || 0}/users/${_course_user.user_id ?? 0}`;
			const response = await api.put(url, _course_user);
			if (response.status === 200) {
				return response.data as CourseUser;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		updateMergedUser({ commit }: { commit: Commit }, _merged_user: MergedUser): void {
			commit('UPDATE_MERGED_USER', _merged_user);
		},

		deleteMergedCourseUser({ commit }: { commit: Commit }, _merged_user: MergedUser): void {
			commit('DELETE_MERGED_USER', _merged_user);
		},
		async deleteCourseUser({ commit, rootState }: { commit: Commit; rootState: StateInterface },
			_course_user: CourseUser) {
			const course_id = rootState.session.course.course_id;
			const response = await api.delete(`courses/${course_id}/users/${_course_user.user_id || 0}`);
			if (response.status === 200) {
				commit('DELETE_COURSE_USER', _course_user);
				return response.data as User;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		async deleteUser({ commit }: { commit: Commit}, _user: User): Promise<User | undefined> {
			const response = await api.delete(`/users/${_user.user_id || 0}`);
			if (response.status === 200) {
				commit('DELETE_USER', _user);
				return response.data as User;
			} else if (response.status === 250) {
				logger.error(response.data);
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
		SET_MERGED_USERS(state: UserState, _merged_users: Array<MergedUser>): void {
			state. merged_users = _merged_users;
		},
		SET_COURSE_USERS(state: UserState, _course_users: Array<CourseUser>): void {
			state.course_users = _course_users;
		},
		ADD_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			state.course_users.push(_course_user);
		},
		ADD_MERGED_USER(state: UserState, _merged_user: MergedUser): void {
			state. merged_users.push(_merged_user);
		},
		UPDATE_MERGED_USER(state: UserState, _merged_user: MergedUser): void {
			const index = state. merged_users.findIndex((u) => u.course_user_id === _merged_user.course_user_id);
			// splice is used so vue3 reacts to changes.
			state. merged_users.splice(index, 1, _merged_user);
		},
		DELETE_COURSE_USER(state: UserState, _course_user: CourseUser): void {
			state.course_users.filter((u) => u.course_user_id !== _course_user.course_user_id);
		},
		DELETE_MERGED_USER(state: UserState, _merged_user: MergedUser): void {
			state.merged_users.filter((u) => u.course_user_id !== _merged_user.course_user_id);
		}
	}
};

async function addUser(_user: User) {
	const response = await api.post('users', _user);
	if (response.status === 200) {
		const u = response.data as ParseableUser;
		u.username;
		return new User(u);
	} else if (response.status === 250) {
		logger.error(response.data);
		throw response.data as ResponseError;
	}
}

async function addCourseUser(_course_user: CourseUser) {
	const response = await api.post(`courses/${_course_user.course_id ?? 0}/users`, _course_user);
	if (response.status === 200) {
		const u = response.data as ParseableCourseUser;
		return new CourseUser(u);
	} else if (response.status === 250) {
		logger.error(response.data);
		throw response.data as ResponseError;
	}
}

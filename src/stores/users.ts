import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { logger } from 'boot/logger';
import type { ParseableCourseUser, ParseableUser } from 'src/common/models/users';
import { User, MergedUser, CourseUser } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { UserCourse } from 'src/common/models/courses';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
}

export const useUserStore = defineStore('user', {
	// state of the Store as a function:
	state: (): UserState => ({
		users: [],
		course_users: [],
		user_courses: []
	}),
	getters: {
		merged_users: (state) => state.course_users.map(course_user =>
			new MergedUser(
				Object.assign(
					course_user.toObject(),
					state.users.find(u => u.user_id === course_user.user_id)?.toObject() ?? {}
				)
			)
		),
		findMergedUser(state) {
			return (user_info: { course_user_id?: number; user_id?: number; username?: string }) => {
				let user: User;
				let course_user: CourseUser;
				console.log(user_info);
				if (user_info.course_user_id) {
					course_user = (this.course_users
						.find(user => user.course_user_id === user_info.course_user_id) as CourseUser) ?? new CourseUser();
					console.log(course_user);
					console.log(this.users);
					user = (this.users.find(user => user.user_id === course_user.user_id) as User) ?? new User();
					console.log(user);
				} else {
					user = (( user_info.user_id ?
						this.users.find(user => user.user_id === user_info.user_id) :
						this.users.find(user => user.username === user_info.username)) as User) ?? new User();
					course_user = (this.course_users
						.find(course_user => user.user_id === course_user.user_id) as CourseUser) ?? new CourseUser();
				}
				return new MergedUser(Object.assign(user.toObject(), course_user.toObject()));
			}
		}
	},
	actions: {
		// no context as first argument, use `this` instead
		async fetchUsers(): Promise<void | ResponseError> {
			const response = await api.get('users');
			if (response.status === 200) {
				const users_to_parse = response.data as Array<User>;
				this.users = users_to_parse.map(user => new User(user));
			} else {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		// This fetches global users in a single course.
		// the users are stored in the same users field as the all global users
		// Perhaps this is a problem.
		async fetchGlobalCourseUsers(course_id: number) {
			const response = await api.get(`courses/${course_id}/global-users`);
			if (response.status === 200) {
				const users = response.data as ParseableUser[];
				this.users = users.map(user => new User(user));
			} else if (response.status == 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async fetchUserCourses(user_id: number): Promise<void | ResponseError> {
			const response = await api.get(`users/${user_id}/courses`);
			if (response.status === 200) {
				this.user_courses = response.data as Array<UserCourse>;
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async getUser(username: string): Promise<ParseableUser | void> {
			const response = await api.get(`users/${username}`);
			if (response.status === 200) {
				return response.data as ParseableUser;
			} else if (response.status === 250) {
				throw response.data as ResponseError;
			}
		},
		async addUser(user: User): Promise<User | undefined> {
			const response = await api.post('users', user.toObject());
			if (response.status === 200) {
				const new_user = new User(response.data as ParseableUser);
				this.users.push(new_user);
				return new_user;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		async updateUser(user: User): Promise<User | undefined> {
			const response = await api.put(`users/${user.user_id}`, user.toObject());
			if (response.status === 200) {
				const updated_user = new User(response.data as ParseableUser);
				const index = this.users.findIndex(user => user.user_id === updated_user.user_id);
				// splice is used so vue3 reacts to changes.
				this.users.splice(index, 1, updated_user);
				return updated_user;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		async deleteUser(user: User): Promise<User | undefined> {
			const response = await api.delete(`/users/${user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.users.findIndex((u) => u.user_id === user.user_id);
				// splice is used so vue3 reacts to changes.
				this.users.splice(index, 1);
				return new User(response.data as ParseableUser);
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		// CourseUser actions
		async fetchCourseUsers(course_id: number): Promise<void | ResponseError> {
			const response = await api.get(`courses/${course_id}/users`);
			if (response.status === 200) {
				const course_users = response.data as ParseableCourseUser[];
				this.course_users = course_users.map(u => new CourseUser(u));
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async addCourseUser(course_user: CourseUser): Promise<CourseUser> {
			const response = await api.post(`courses/${course_user.course_id ?? 0}/users`,
				course_user.toObject());
			if (response.status === 200) {
				const new_course_user = new CourseUser(response.data as ParseableCourseUser);
				this.course_users.push(new_course_user);
				return new_course_user;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
			return new CourseUser();
		},
		async updateCourseUser(course_user: CourseUser): Promise<CourseUser | undefined> {
			const url = `courses/${course_user.course_id || 0}/users/${course_user.user_id ?? 0}`;
			const response = await api.put(url, course_user.toObject());
			if (response.status === 200) {
				const index = this.course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				const course_user_to_update = new CourseUser(response.data as ParseableCourseUser);
				this.course_users.splice(index, 1, course_user_to_update);
				return course_user_to_update;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		async deleteCourseUser(course_user: CourseUser): Promise<CourseUser | undefined> {
			const course_id = course_user.course_id ?? 0;
			const response = await api.delete(`courses/${course_id}/users/${course_user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				this.course_users.splice(index, 1);
				return new CourseUser(response.data as ParseableCourseUser);
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		}
	}
});

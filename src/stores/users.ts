import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { logger } from 'boot/logger';
import type { ParseableCourseUser, ParseableMergedUser, ParseableUser } from 'src/common/models/users';
import { User, MergedUser, CourseUser } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { UserCourse } from 'src/common/models/courses';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
	merged_users: Array<MergedUser>;
	set_users: Array<User>;
}

export const useUserStore = defineStore('user', {
	// state of the Store as a function:
	state: (): UserState => ({
		users: [],
		course_users: [],
		merged_users: [],
		user_courses: [],
		set_users: []
	}),
	actions: {
		// no context as first argument, use `this` instead
		async fetchUsers(): Promise<void | ResponseError> {
			const response = await api.get('users');
			if (response.status === 200) {
				this.users = response.data as Array<User>;
			} else {
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
		async fetchCourseUsers(course_id: number): Promise<void | ResponseError> {
			const response = await api.get(`courses/${course_id}/users`);
			if (response.status === 200) {
				const course_users = response.data as Array<ParseableCourseUser>;
				this.course_users = course_users.map(u => new CourseUser(u));
			} else if (response.status === 250) {
				logger.error(response.data);
				return response.data as ResponseError;
			}
		},
		async fetchMergedUsers(course_id: number): Promise<void | ResponseError> {
			const response = await api.get(`courses/${course_id}/courseusers`);
			if (response.status === 200) {
				const merged_users = response.data as Array<ParseableMergedUser>;
				this.merged_users = merged_users.map(u => new MergedUser(u));
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
		async addUser(user: User): Promise<User | void> {
			const response = await api.post('users', user.toObject());
			if (response.status === 200) {
				this.users.push(new User(response.data as ParseableUser));
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
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
		async addMergedUser(merged_user: MergedUser): Promise<MergedUser> {
			// If this is a new user (user_id == 0) then add the user.
			if (merged_user.user_id === 0) {
				const response = await api.post('users', merged_user.toObject(User.ALL_FIELDS));

				if (response.status === 200) {
					const user = new User(response.data as ParseableUser);
					this.users.push(user);
					merged_user.user_id = user.user_id;
					merged_user.username = user.username;
				} else if (response.status === 250) {
					logger.error(response.data);
					throw response.data as ResponseError;
				}
			}
			const new_course_user
				= await this.addCourseUser(new CourseUser(merged_user.toObject(CourseUser.ALL_FIELDS)));
			if (new_course_user) {
				this.course_users.push(new_course_user);
				merged_user.course_user_id = new_course_user.course_user_id;
				this.merged_users.push(merged_user);
			}

			return merged_user;
		},
		async updateCourseUser(course_user: CourseUser): Promise<void> {
			const url = `courses/${course_user.course_id || 0}/users/${course_user.user_id ?? 0}`;
			const response = await api.put(url, course_user.toObject());
			if (response.status === 200) {
				const index = this.course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				this.course_users.splice(index, 1, new CourseUser(response.data as ParseableCourseUser));
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		updateMergedUser(merged_user: MergedUser): void {
			const index = this.merged_users.findIndex((u) => u.course_user_id === merged_user.course_user_id);
			// splice is used so vue3 reacts to changes.
			this.merged_users.splice(index, 1, merged_user);
		},

		deleteMergedUser(merged_user: MergedUser): void {
			const index = this.merged_users.findIndex((u) => u.course_user_id === merged_user.course_user_id);
			// splice is used so vue3 reacts to changes.
			this.merged_users.splice(index, 1);
		},
		async deleteCourseUser(course_user: CourseUser): Promise<void> {
			const course_id = course_user.course_id ?? 0;
			const response = await api.delete(`courses/${course_id}/users/${course_user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				this.course_users.splice(index, 1);
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		async deleteUser(user: User): Promise<void> {
			const response = await api.delete(`/users/${user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.users.findIndex((u) => u.user_id === user.user_id);
				// splice is used so vue3 reacts to changes.
				this.users.splice(index, 1);
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		}
	}

});

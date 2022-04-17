import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { logger } from 'boot/logger';
import type { ParseableCourseUser, ParseableUser } from 'src/common/models/users';
import { User, MergedUser, CourseUser } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { UserCourse } from 'src/common/models/courses';
import { UserRole } from 'src/common/models/parsers';

export interface UserState {
	users: Array<User>;
	user_courses: Array<UserCourse>;
	course_users: Array<CourseUser>;
}

// A type for requesting a course user from the store.

type CourseUserInfo =
	{ user_id: number; username?: never; course_user_id?: never } |
	{ username: string; user_id?: never; course_user_id?: never } |
	{ course_user_id: number; username?: never; user_id?: never};

/**
 * Creates the user store, which stores both global users and course users.
 */
export const useUserStore = defineStore('user', {
	// state of the Store as a function:
	state: (): UserState => ({
		users: [],
		course_users: [],
		user_courses: []
	}),
	getters: {
		/**
		 * returns all course users merged with the global users.
		 */
		merged_users: (state) => state.course_users.map(course_user =>
			new MergedUser(
				Object.assign(
					course_user.toObject(),
					state.users.find(u => u.user_id === course_user.user_id)?.toObject() ?? {}
				)
			)
		),
		/**
		 * returns a merged user from the store if the user exists.
		 * @param user_info {UserInfo} - either a course_user_id or combination of set and user info.
		 * @returns {MergedUser} -- the requested merged user.
		 */
		findMergedUser(state) {
			return (user_info: CourseUserInfo) => {
				let user: User;
				let course_user: CourseUser;
				if (user_info.course_user_id) {
					course_user = (state.course_users
						.find(user => user.course_user_id === user_info.course_user_id) as CourseUser)
							?? new CourseUser();
					user = (state.users.find(user => user.user_id === course_user.user_id) as User) ?? new User();
				} else {
					user = ((user_info.user_id ?
						state.users.find(user => user.user_id === user_info.user_id) :
						state.users.find(user => user.username === user_info.username)) as User) ?? new User();
					course_user = (this.course_users
						.find(course_user => user.user_id === course_user.user_id) as CourseUser) ?? new CourseUser();
				}
				return new MergedUser(Object.assign(user.toObject(), course_user.toObject()));
			};
		},
		getUserByName: (state) =>
			(_username: string) => state.users.find((_user) => _user.username === _username),
		getCourseUsersByRole: (state) =>
			(_role: UserRole) => state.course_users.filter((_user) => _user.role === _role)
	},
	actions: {
		/**
		 * fetch all users in all courses.
		 */
		async fetchUsers(): Promise<void> {
			logger.debug('[UserStore/fetchUsers] fetching users...');
			const response = await api.get('users');
			if (response.status === 200) {
				const users_to_parse = response.data as Array<User>;
				this.users = users_to_parse.map(user => new User(user));
			} else {
				const error = response.data as ResponseError;
				logger.error(`${error.exception}: ${error.message}`);
				throw new Error(error.message);
			}
		},
		/**
		 * fetch the global users for a given course.
		 * @param {number} course_id: the database course id
		 */
		// the users are stored in the same users field as the all global users
		// Perhaps this is a problem.
		async fetchGlobalCourseUsers(course_id: number) {
			const response = await api.get(`courses/${course_id}/global-users`);
			if (response.status === 200) {
				const users = response.data as ParseableUser[];
				this.users = users.map(user => new User(user));
			} else if (response.status == 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		/**
		 * fetch all User Courses for a given user.
		 * @param {number} user_id
		 */
		// perhaps this should be in the session store?
		async fetchUserCourses(user_id: number): Promise<void> {
			logger.debug(`[UserStore/fetchUserCourses] fetching courses for user #${user_id}`);
			const response = await api.get(`users/${user_id}/courses`);
			if (response.status === 200) {
				this.user_courses = response.data as Array<UserCourse>;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		/**
		 * updates the user in the database and in the store.
		 * @param {User} user -- the user to be updated.
		 * @returns {User} -- the updated user.
		 */
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
		/**
		 * deletes the user in the database and in the store.
		 * @param {User} user -- the user to be deleted.
		 * @returns {User} the added user
		 */
		async deleteUser(user: User): Promise<User | undefined> {
			const response = await api.delete(`/users/${user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.users.findIndex((u) => u.user_id === user.user_id);
				// splice is used so vue3 reacts to changes.
				this.users.splice(index, 1);
				return new User(response.data as ParseableUser);
			}
		},
		/**
		 * adds the user to the database and to the store.
		 * @param {User} user -- the user to be added.
		 * @returns {User} the added user
		 */
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
		// CourseUser actions
		/**
		 * fetches course users from the database for a given course.
		 * @param {number} course_id - the id of the course in the database.
		 */
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
		/**
		 * adds a Course User to the store and the database.
		 * @param {CourseUser} course_user - the course user to add
		 * @returns the added course user.
		 */
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
		/**
		 * updates a Course User to the store and the database.
		 * @param {CourseUser} course_user - the course user to update
		 * @returns the updated course user.
		 */
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
		/**
		 * deletes a Course User from the store and the database.
		 * @param {CourseUser} course_user - the course user to delete
		 * @returns the deleted course user.
		 */
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

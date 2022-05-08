import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { logger } from 'boot/logger';
import { DBCourseUser, ParseableCourseUser, ParseableDBCourseUser, ParseableUser } from 'src/common/models/users';
import { User, CourseUser } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { UserRole } from 'src/common/models/parsers';

export interface UserState {
	users: User[];
	db_course_users: DBCourseUser[];
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
		db_course_users: []
	}),
	getters: {
		/**
		 * returns all course users merged with the global users.
		 */
		course_users: (state) => state.db_course_users.map(course_user =>
			new CourseUser(
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
		findCourseUser(state) {
			return (user_info: CourseUserInfo) => {
				let user: User;
				let db_course_user: DBCourseUser;

				if (user_info.course_user_id) {
					db_course_user = (state.db_course_users
						.find(user => user.course_user_id === user_info.course_user_id) as DBCourseUser)
							?? new CourseUser();
					user = (state.users.find(user => user.user_id === db_course_user.user_id) as User)
						?? new User({ username: '__NEW__' });
				} else {
					user = ((user_info.user_id ?
						state.users.find(user => user.user_id === user_info.user_id) :
						state.users.find(user => user.username === user_info.username)) as User)
							?? new User({ username: '__NEW__' });
					db_course_user = (this.db_course_users
						.find(course_user => user.user_id === course_user.user_id) as DBCourseUser) ?? new CourseUser();
				}
				return new CourseUser(Object.assign(user.toObject(), db_course_user.toObject()));
			};
		},
		getUserByName: (state) =>
			(_username: string) => state.users.find((_user) => _user.username === _username),
		getCourseUsersByRole: (state) =>
			(_role: UserRole) => state.db_course_users.filter((_user) => _user.role === _role)
	},
	actions: {
		/**
		 * fetch all global users in all courses.
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
				const course_users = response.data as ParseableDBCourseUser[];
				this.db_course_users = course_users.map(u => new DBCourseUser(u));
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
			// When sending, only send the DBCourseUser fields.
			const response = await api.post(`courses/${course_user.course_id}/users`,
				course_user.toObject(DBCourseUser.ALL_FIELDS));
			if (response.status === 200) {
				const new_course_user = new DBCourseUser(response.data as ParseableDBCourseUser);
				this.db_course_users.push(new_course_user);
				return this.findCourseUser({ course_user_id: new_course_user.course_user_id });
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
			// When sending, only send the DBCourseUser fields.
			const response = await api.put(url, course_user.toObject(DBCourseUser.ALL_FIELDS));
			if (response.status === 200) {
				const course_user_to_update = new DBCourseUser(response.data as ParseableDBCourseUser);
				const index = this.course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				this.db_course_users.splice(index, 1, course_user_to_update);
				return this.findCourseUser({ course_user_id: course_user_to_update.course_user_id });
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
			const response = await api.delete(`courses/${course_user.course_id}/users/${course_user.user_id}`);
			if (response.status === 200) {
				const index = this.db_course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);
				// splice is used so vue3 reacts to changes.
				this.course_users.splice(index, 1);
				const deleted_course_user = new DBCourseUser(response.data as ParseableCourseUser);
				const user = this.users.find(u => u.user_id === deleted_course_user.user_id);
				return new CourseUser(Object.assign(user?.toObject(), deleted_course_user.toObject()));
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		}
	}
});

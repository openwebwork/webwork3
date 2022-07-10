import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { logger } from 'boot/logger';
import { DBCourseUser, ParseableCourseUser, ParseableDBCourseUser, ParseableUser } from 'src/common/models/users';
import { User, CourseUser } from 'src/common/models/users';
import { invalidError, ResponseError } from 'src/common/api-requests/errors';
import { UserRole } from 'src/stores/permissions';
import { useSessionStore } from './session';

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
	state: (): UserState => ({
		users: [],
		db_course_users: []
	}),
	getters: {

		/**
		 * Returns all course users merged with the global users.
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
		 * Returns a merged user from the store with given course_name or course_id and username or
		 * user_id.
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

		/**
		 * Returns a user given a username.
		 */
		getUserByName: (state) =>
			(_username: string) => state.users.find((_user) => _user.username === _username),

		/**
		 * Returns all course users in the store with a given role.
		 */
		getCourseUsersByRole: (state) =>
			(_role: UserRole) => state.db_course_users.filter((_user) => _user.role === _role)
	},
	actions: {

		/**
		 * Fetch all global users in all courses and store the results.
		 */
		async fetchUsers(): Promise<void> {
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
		 * Fetch the global users for a given course and store the results.
		 */
		// the users are stored in the same users field as the all global users
		// Perhaps this is a problem.
		async fetchGlobalCourseUsers(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/global-courseusers`);
			if (response.status === 200) {
				const users = response.data as ParseableUser[];
				this.users = users.map(user => new User(user));
			} else if (response.status == 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},

		/**
		 * Updates the given user in the database and in the store.
		 */
		async updateUser(user: User): Promise<User | undefined> {
			if (!user.isValid()) await invalidError(user, 'The updated user is invalid');

			const session_store = useSessionStore();
			const course_id = session_store.course.course_id;
			const response = await api.put(`courses/${course_id}/global-users/${user.user_id}`, user.toObject());
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
		 * Deletes the given User in the database and in the store.
		 */
		async deleteUser(user: User): Promise<User | undefined> {
			const session_store = useSessionStore();
			const course_id = session_store.course.course_id;
			const response = await api.delete(`courses/${course_id}/global-users/${user.user_id ?? 0}`);
			if (response.status === 200) {
				const index = this.users.findIndex((u) => u.user_id === user.user_id);
				// splice is used so vue3 reacts to changes.
				this.users.splice(index, 1);
				return new User(response.data as ParseableUser);
			}
		},

		/**
		 * Adds the given User to the database and to the store.
		 */
		async addUser(user: User): Promise<User | undefined> {
			if (!user.isValid()) await invalidError(user, 'The added user is invalid');

			const session_store = useSessionStore();
			const course_id = session_store.course.course_id;
			const response = await api.post(`courses/${course_id}/global-users`, user.toObject());
			if (response.status === 200) {
				const new_user = new User(response.data as ParseableUser);
				this.users.push(new_user);
				return new_user;
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		/**
		 * This addes the session user to the users field in the store.  This is
		 * needed for other stores and merged models.
		 */
		async setSessionUser() {
			const session_store = useSessionStore();
			// if there is no user in the session don't fetch the user.
			if (session_store.user.user_id === 0) return;
			// Get the global user.
			const user_response = await api.get(`users/${session_store.user.user_id}`);
			this.users = [ new User(user_response.data as ParseableUser)];
			// fetch the course user information for this use
			const response = await api.get(`courses/${session_store.course.course_id}/users/${
				session_store.user.user_id}`);
			this.db_course_users = [ new DBCourseUser(response.data as ParseableDBCourseUser)];
		},
		// CourseUser actions

		/**
		 * fetches course users from the database for a given course.
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
		 * Adds the given Course User to the store and the database.
		 */
		async addCourseUser(course_user: CourseUser): Promise<CourseUser> {
			if (!course_user.isValid()) return invalidError(course_user, 'The added course user is invalid');

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
		 * Updates the given Course User to the store and the database.
		 */
		async updateCourseUser(course_user: CourseUser): Promise<CourseUser | undefined> {
			if (!course_user.isValid()) return invalidError(course_user, 'The updated course user is invalid');

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
		 * Deletes a Course User from the store and the database.
		 */
		async deleteCourseUser(course_user: CourseUser): Promise<CourseUser | undefined> {
			const response = await api.delete(`courses/${course_user.course_id}/users/${course_user.user_id}`);
			if (response.status === 200) {
				const index = this.db_course_users.findIndex((u) => u.course_user_id === course_user.course_user_id);

				// splice is used so vue3 reacts to changes.
				this.db_course_users.splice(index, 1);
				const deleted_course_user = new DBCourseUser(response.data as ParseableCourseUser);
				const user = this.users.find(u => u.user_id === deleted_course_user.user_id);
				return new CourseUser(Object.assign({}, user?.toObject(), deleted_course_user.toObject()));
			} else if (response.status === 250) {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		clearAll() {
			this.users = [];
			this.db_course_users = [];
		}
	}
});

// This store is for problem sets, user sets, merged user sets and set problems.

import { defineStore } from 'pinia';
import { api } from 'boot/axios';
import { logger } from 'boot/logger';

import { useSessionStore } from './session';
import { useUserStore } from './users';

import { parseProblemSet, ProblemSet, ParseableProblemSet } from 'src/common/models/problem_sets';
import {
	UserSet, mergeUserSet, DBUserSet, ParseableDBUserSet, parseDBUserSet
} from 'src/common/models/user_sets';
import { CourseUser } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/interfaces';

/**
 * This is an type to retrieve set info.
 */
type SetInfo =
	{ set_name: string; set_id?: never } |
	{ set_id: number; set_name?: never};

type UserInfo =
	{ username: string; user_id?: never } |
	{ user_id: number; username?: never };

/**
 * This is an type to retrieve user set info.  This ensure either a user_set_id is passed
 * in or set info and User Info, but not too much.
 */
type UserSetInfo =
	{ user_set_id: number; set_id?: never; set_name?: never; user_id?: never; username?: never } |
	{ set_id: number; user_id: number; user_set_id?: never; set_name?: never; username?: never; } |
	{ set_id: number; username: string; user_set_id?: never; set_name?: never; user_id?: never; } |
	{ set_name: string; user_id: number; user_set_id?: never; set_id?: never; username?: never; } |
	{ set_name: string; username: string; user_set_id?: never; set_id?: never; user_id?: never; };

/* The store stores only the problem_sets and user_set from the database (type DBUserSet).
 * however user sets are found via getters.
 */
export interface ProblemSetState {
	problem_sets: ProblemSet[];
	db_user_sets: DBUserSet[];
}

export const useProblemSetStore = defineStore('problem_sets', {
	state: (): ProblemSetState => ({
		problem_sets: [],
		db_user_sets: [],
	}),
	getters: {

		/**
		 * Returns all User Sets (merge between Problem Set and a DBUserSet)
		 */
		user_sets: (state) => state.db_user_sets.map(db_user_set => {
			const problem_set = state.problem_sets.find(set => set.set_id == db_user_set.set_id);
			const course_user = useUserStore()
				.course_users.find(u => u.course_user_id === db_user_set.course_user_id);
			return mergeUserSet(problem_set as ProblemSet, db_user_set as DBUserSet, course_user as CourseUser)
				?? new UserSet();
		}),

		/**
		 * Returns a ProblemSet given either the set_id or set_name.
		 */
		findProblemSet: (state) => (set_info: SetInfo) =>
			set_info.set_id ?
				state.problem_sets.find(set => set.set_id === set_info.set_id) :
				state.problem_sets.find(set => set.set_name === set_info.set_name),

		/**
		 * Returns all user sets with given a set_id or set_name.
		 */
		findUserSets(state) {
			// TODO: for performance, maybe don't call this.user_sets, but build up the
			// user_sets instead.
			return (set_info: SetInfo): UserSet[] => {
				if (set_info.set_id) {
					return this.user_sets.filter(user_set => user_set.set_id === set_info.set_id);
				} else if (set_info.set_name) {
					const set = state.problem_sets.find(set => set.set_name === set_info.set_name);
					if (set) {
						return this.user_sets.filter(user_set => user_set.set_id === set.set_id) ;
					} else {
						return [];
					}
				} else {
					return [];
				}
			};
		},

		/**
		 * Find a merged user set for a given set_id or set name and user_id or username.
		 */
		findUserSet(state) {
			return (user_set_info: UserSetInfo): UserSet | undefined => {
				const user_store = useUserStore();
				let db_user_set: DBUserSet;
				let problem_set: ProblemSet;
				let user: CourseUser;

				if (user_set_info.user_set_id) {
					db_user_set = (state.db_user_sets
						.find(set => set.user_set_id == user_set_info.user_set_id) as DBUserSet) ?? new DBUserSet();
					problem_set = state.problem_sets.find(set => set.set_id === db_user_set.set_id) as ProblemSet;
					user = user_store.findCourseUser({ course_user_id: db_user_set.course_user_id });
				} else if (user_set_info.username) {
					problem_set = ((user_set_info.set_id ?
						state.problem_sets.find(set => set.set_id === user_set_info.set_id) :
						state.problem_sets.find(set => set.set_name === user_set_info.set_name))
							?? new ProblemSet()) as ProblemSet;
					user = user_store.findCourseUser({ username: user_set_info.username });
					db_user_set = state.db_user_sets.find(set => set.set_id === problem_set.set_id &&
						set.course_user_id === user.course_user_id) as DBUserSet ?? new DBUserSet();
				} else {
					return;
				}
				return mergeUserSet(problem_set, db_user_set, user);
			};
		}
	},
	actions: {

		/**
		 * Fetches all problem sets for the given course and stores the results.
		 */
		async fetchProblemSets(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/sets`);
			const sets_to_parse = response.data as Array<ParseableProblemSet>;
			this.problem_sets = sets_to_parse.map((set) => parseProblemSet(set));
		},

		/**
		 * Adds the given problem set to the store and the database.
		 */
		async addProblemSet(set: ProblemSet): Promise<ProblemSet> {
			const response = await api.post(`courses/${set.course_id}/sets`, set.toObject());
			const new_set = parseProblemSet(response.data as ParseableProblemSet);
			this.problem_sets.push(new_set);
			return new_set;
		},

		/**
		 * Updates the given set in the store and the database.
		 */
		async updateSet(set: ProblemSet): Promise<ProblemSet | undefined> {
			const response = await api.put(`courses/${set.course_id}/sets/${set.set_id}`, set.toObject());
			if (response.status === 200) {
				const updated_set = parseProblemSet(response.data as ParseableProblemSet);
				// This is being handled in the tests, so we probably don't need to test for each
				// request.
				if (JSON.stringify(updated_set) !== JSON.stringify(set)) {
					logger.error('[updateSet] response does not match requested update to set');
				}
				const index = this.problem_sets.findIndex(s => s.set_id === set.set_id);
				this.problem_sets[index] = updated_set;
				return updated_set;
			} else {
				const error = response.data as ResponseError;
				logger.error(`Error updating set: ${error.message}`);
				throw new Error(error.message);
				// TODO: app-level error handling -- should throw here
			}
			// The following is not working.  TODO: fix-me
			// if (JSON.stringify(set) === JSON.stringify(_set)) {
			// commit('UPDATE_PROBLEM_SET', _set);
			// } else {
			// logger.error(`Problem set #${_set.set_id ?? 0} failed to update properly.`);
			// }

		},

		/**
		 * Delete the given ProblemSet from the database and the store.
		 */
		async deleteProblemSet(set: ProblemSet) {
			const response = await api.delete(`courses/${set.course_id}/sets/${set.set_id}`);
			const set_to_delete = parseProblemSet(response.data as ParseableProblemSet);
			const index = this.problem_sets.findIndex(set => set.set_id === set_to_delete.set_id);
			if (index >= 0) {
				this.problem_sets.splice(index, 1);
			}
			// TODO: what if this fails
			return set_to_delete;
		},
		// UserSet actions

		/**
		 * Fetches all user sets for a given course and stores the results.
		 */
		async fetchAllUserSets(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/user-sets`);
			const user_sets_to_parse = response.data as ParseableDBUserSet[];
			this.db_user_sets = user_sets_to_parse.map(user_set => parseDBUserSet(user_set));
		},

		/**
		 * Fetch all user sets in a given course_id and given set_id.  The results are stored.
		 */
		async fetchUserSets(params: { course_id: number; set_id: number}) {
			const response = await api.get(`courses/${params.course_id}/sets/${params.set_id}/users`);
			const user_sets_to_parse = response.data as ParseableDBUserSet[];
			this.db_user_sets = user_sets_to_parse.map(user_set => parseDBUserSet(user_set));
		},

		/**
		 * Fetches all user sets for a given user in the current course (from the session) and store
		 * the results.
		 */
		async fetchUserSetsForUser(params: UserInfo) {
			const course_id = useSessionStore().course.course_id;
			const user_store = useUserStore();
			let user_id: number;
			if (params.username) {
				const user = user_store.users.find(u => u.username === params.username);
				user_id = user?.user_id ?? 0;
			} else {
				user_id = params.user_id ?? 0;
			}
			const response = await api.get(`courses/${course_id}/users/${user_id}/sets`);
			this.db_user_sets = (response.data as ParseableDBUserSet[]).map(user_set => parseDBUserSet(user_set));
		},

		/**
		 * Adds a User Set to the store and the database.
		 */
		async addUserSet(user_set: UserSet): Promise<UserSet | undefined> {
			const course_id = useSessionStore().course.course_id;
			const response = await api.post(`courses/${course_id}/sets/${user_set.set_id}/users`,
				user_set.toObject(DBUserSet.ALL_FIELDS));
			// TODO: check for errors
			const user_set_to_add = parseDBUserSet(response.data as ParseableDBUserSet);
			if (user_set_to_add) {
				this.db_user_sets.push(user_set_to_add);
				user_set.set(user_set_to_add.toObject());
				return user_set;
			}
		},

		/**
		 * Updates the given UserSet to the store and the database.
		 */
		async updateUserSet(set: UserSet): Promise<UserSet> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;
			const response = await api.put(`courses/${course_id}/sets/${set.set_id ?? 0}/users/${
				set.course_user_id ?? 0}`, set.toObject(UserSet.ALL_FIELDS));
			const updated_user_set = parseDBUserSet(response.data as ParseableDBUserSet);

			// TODO: check for errors
			const index = this.db_user_sets.findIndex(s => s.user_set_id === updated_user_set.user_set_id);
			this.db_user_sets.splice(index, 1, updated_user_set);
			set.set(updated_user_set.toObject());
			return set;
		},

		/**
		 * Deletes the given UserSet from the store and the database.
		 */
		async deleteUserSet(user_set: UserSet) {
			const course_id = useSessionStore().course.course_id;
			const response = await
				api.delete(`courses/${course_id}/sets/${user_set.set_id}/users/${user_set.course_user_id ?? 0}`);
			// TODO: check for errors
			const deleted_user_set = parseDBUserSet(response.data as ParseableDBUserSet);
			const index = this.db_user_sets.findIndex(s => s.user_set_id === deleted_user_set.user_set_id);
			this.db_user_sets.splice(index, 1);
			user_set.set(deleted_user_set.toObject());
			return user_set;
		},

		/**
		 * Clears all objects from the store.
		 */
		clearAll() {
			this.db_user_sets = [];
			this.problem_sets = [];
		}
	}
});

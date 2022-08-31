// This store handles set problems and user problems.

import { api } from 'boot/axios';
import { defineStore } from 'pinia';
import { logger } from 'src/boot/logger';
import { invalidError } from 'src/common/api-requests/errors';

import { ParseableProblem, parseProblem, SetProblem, ParseableSetProblem, UserProblem,
	mergeUserProblem, DBUserProblem, ParseableDBUserProblem, LibraryProblem } from 'src/common/models/problems';
import { UserSet } from 'src/common/models/user_sets';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from './problem_sets';

export interface SetProblemsState {
	set_problems: SetProblem[];
	db_user_problems: DBUserProblem[];
}

type SetInfo =
	{ set_id: number; set_name?: never } |
	{ set_name: string; set_id?: never };

export const useSetProblemStore = defineStore('set_problems', {
	state: (): SetProblemsState => ({
		set_problems: [],
		db_user_problems: []
	}),
	getters: {

		/**
		 * Returns all set problems with given set_id or set_name.
		 */
		findSetProblems: (state) => (set_info: SetInfo): SetProblem[] => {
			if (set_info.set_id) {
				return state.set_problems.filter(prob => prob.set_id === set_info.set_id) as SetProblem[];
			} else if (set_info.set_name) {
				const problem_set_store = useProblemSetStore();
				const set = problem_set_store.problem_sets.find(set => set.set_name === set_info.set_name);
				if (set) {
					return state.set_problems.filter(prob => prob.set_id === set.set_id) as SetProblem[];
				} else {
					return [];
				}
			} else {
				return [];
			}
		},

		/**
		 * Return the user problems with a given set_id or set_name
		 */
		// Note: using standard function notation (not arrow) due to using this.
		findUserProblems(state) {
			return (set_info: SetInfo) => {
				const problem_set_store = useProblemSetStore();
				// get a list of the desired set_problem_ids
				const set_problem_ids = this.findSetProblems(set_info).map(prob => prob.set_problem_id);
				return state.db_user_problems
					.filter(user_prob => set_problem_ids
						.findIndex(prob_id => user_prob.set_problem_id === prob_id) >= 0)
					.map(user_prob => {
						const user_set = problem_set_store.findUserSet({ user_set_id: user_prob.user_set_id })
							?? new UserSet();
						const set_problem = state
							.set_problems.find(prob => prob.set_problem_id === user_prob.set_problem_id)
							?? new SetProblem();
						// Not sure why the first two arguments need to be cast.
						return mergeUserProblem(set_problem as SetProblem, user_prob as DBUserProblem, user_set);
					});
			};
		},

		/**
		 * Returns all user problems merged with their corresponding set problems.
		 */
		user_problems: (state) => {
			const problem_set_store = useProblemSetStore();
			return state.db_user_problems.map(user_problem => {
				const user_set = problem_set_store.findUserSet({ user_set_id: user_problem.user_set_id })
					?? new UserSet();
				const set_problem = state.set_problems.find(prob => prob.set_problem_id === user_problem.set_problem_id)
					?? new SetProblem();
				// Not sure why the first two arguments need to be cast.
				return mergeUserProblem(set_problem as SetProblem, user_problem as DBUserProblem, user_set);
			});
		},

		/**
		 * Return a single user problem with given user_problem_id.`
		 */
		findUserProblem: (state) => (user_problem_id: number) => {
			const problem_set_store = useProblemSetStore();
			const db_user_problem = state.db_user_problems.find((prob) => prob.user_problem_id === user_problem_id);
			if (db_user_problem == undefined) return;
			const set_problem = state.set_problems
				.find((prob) => prob.set_problem_id == db_user_problem.set_problem_id);
			if (set_problem == undefined) return;
			const user_set = problem_set_store.findUserSet({ user_set_id: db_user_problem.user_set_id });
			if (user_set == undefined) return;
			return mergeUserProblem(set_problem as SetProblem, db_user_problem as DBUserProblem, user_set);
		}
	},
	actions: {

		/**
		 * Fetch all set problems with given course_id.
		 */
		async fetchSetProblems(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/problems`)
				.then((response) => {
					// TODO: throw exceptions via axios hook instead
					if (response.status !== 200) throw (response.data as Error);
					return response.data as Array<ParseableProblem>;
				});
			if (response) this.set_problems = response.map((prob) => parseProblem(prob, 'Set') as SetProblem);
		},

		/**
		 * Adds the given set problem with information from a Library problem and a given
		 * set_id to both the database and the store.
		 */
		async addSetProblem(problem: LibraryProblem, set_id: number): Promise<SetProblem> {
			if (!problem.isValid()) await invalidError(problem, 'The added problem is invalid');

			const session_store = useSessionStore();

			const course_id = session_store.course.course_id;
			if (!course_id) logger.error('[addSetProblem] cannot add problem when session course is not set');

			const prob = new SetProblem({
				problem_params: problem.location_params,
				set_id: set_id
			}).toObject();

			// delete the render params.  Not in the database.
			delete prob.render_params;
			const response = await api.post(`/courses/${course_id}/sets/${set_id}/problems`, prob).
				catch((e: Error) =>
					logger.error(`[addSetProblem] ${JSON.stringify(prob)} failed with ${e.message}`));

			const new_problem = new SetProblem(response.data as ParseableSetProblem);
			this.set_problems.push(new_problem);
			return new_problem;
		},

		/**
		 * Update the given SetProblem in both the database and the store.
		 */
		async updateSetProblem(problem: SetProblem): Promise<SetProblem> {
			if (!problem.isValid()) await invalidError(problem, 'The updated set problem is invalid');

			const course_id = useSessionStore().course.course_id;
			const prob = problem.toObject();
			// delete the render params.  Not in the database.
			delete prob.render_params;

			const response = await api.put(`courses/${course_id}/sets/${problem.set_id}/problems/${
				problem.set_problem_id}`, prob);
			const updated_problem = new SetProblem(response.data as ParseableSetProblem);
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.set_problem_id === updated_problem.set_problem_id);
			this.set_problems.splice(index, 1, updated_problem);
			return updated_problem;
		},

		/**
		 * Delete the given SetProblem in both the store and the database.
		 */
		async deleteSetProblem(problem: SetProblem): Promise<void> {
			const course_id = useSessionStore().course.course_id;
			const index = this.set_problems.findIndex(prob => prob.set_problem_id === problem.set_problem_id);
			if (index >= 0) {
				const response = await api.delete(`courses/${course_id}/sets/${problem.set_id
				}/problems/${problem.set_problem_id}`);
				if (response.status === 200) {
				// splice is used so vue3 reacts to changes.
					this.set_problems.splice(index, 1);
				} else {
					logger.error(JSON.stringify(response));
				}
			} else {
				logger.error('[stores/set_problems/deleteSetProblem]: the set problem was not found in the store');
			}
		},
		// UserProblem actions

		/**
		 * Fetch all user problems for given set via set_id in the current course (from the session).
		 */
		async fetchUserProblems(set_id: number) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.get(`courses/${course_id}/sets/${set_id}/user-problems`);
			this.db_user_problems = (response.data as ParseableDBUserProblem[]).map(prob => new DBUserProblem(prob));
		},

		/**
		 * Fetch all user problems for a user given by user_id in a course (stored in the session)
		 */
		async fetchUserProblemsForUser(user_id: number) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.get(`courses/${course_id}/users/${user_id}/problems`);
			this.db_user_problems = (response.data as ParseableDBUserProblem[]).map(prob => new DBUserProblem(prob));
		},

		/**
		 * Update a given UserProblem in the database and in the store.
		 */
		async updateUserProblem(user_problem: UserProblem): Promise<UserProblem | undefined> {
			const course_id = useSessionStore().course.course_id;
			const set_problem = this.set_problems.find(prob => prob.set_problem_id === user_problem.set_problem_id);
			const user_set = useProblemSetStore().findUserSet({ user_set_id: user_problem.user_set_id });
			// TODO: handle if either set_problem or user_set undefined.

			const user_problem_params = user_problem.toObject(DBUserProblem.ALL_FIELDS);
			// The render params are not stored in the DB.
			delete user_problem_params.render_params;

			const response = await api.put(`courses/${course_id}/sets/${set_problem?.set_id ?? 0}/users/${
				user_set?.user_id ?? 0}/problems/${user_problem.user_problem_id}`, user_problem_params);
			const updated_db_user_problem = new DBUserProblem(response.data as ParseableDBUserProblem);
			const index = this.db_user_problems
				.findIndex(user_problem => user_problem.user_problem_id === updated_db_user_problem.user_problem_id);
			this.db_user_problems.splice(index, 1, updated_db_user_problem);

			// Create a UserProblem to return from the current user problem and the saved
			// db_user_problem.
			return this.findUserProblem(user_problem.user_problem_id);
		},

		/**
		 * Add a given UserProblem to the database and the store.
		 */
		async addUserProblem(user_problem: UserProblem): Promise<UserProblem> {
			const course_id = useSessionStore().course.course_id;
			const set_problem = this.set_problems.find(prob => prob.set_problem_id === user_problem.set_problem_id);
			const user_set = useProblemSetStore().findUserSet({ user_set_id: user_problem.user_set_id });
			// TODO: handle if either set_problem or user_set undefined.

			const user_problem_params = user_problem.toObject(DBUserProblem.ALL_FIELDS);
			// The render params are not stored in the DB.
			delete user_problem_params.render_params;

			const response = await api.post(`courses/${course_id}/sets/${set_problem?.set_id ?? 0}/users/${
				user_set?.user_id ?? 0}/problems`, user_problem_params);
			const added_db_user_problem = new DBUserProblem(response.data as ParseableDBUserProblem);
			this.db_user_problems.push(added_db_user_problem);

			// Create a UserProblem to return from the current user problem and the saved
			// db_user_problem.  The DBUserProblem overrides the values from the broader UserProblem
			const added_user_problem = new UserProblem(Object.assign(user_problem.toObject(),
				added_db_user_problem.toObject()));
			return added_user_problem;
		},

		/**
		 * Delete the given UserProblem from the database and the store.
		 */
		async deleteUserProblem(user_problem: UserProblem): Promise<void> {
			const course_id = useSessionStore().course.course_id;
			const set_problem = this.set_problems.find(prob => prob.set_problem_id === user_problem.set_problem_id);
			const problem_set_store = useProblemSetStore();
			const index = this.db_user_problems
				.findIndex(user_problem => user_problem.user_problem_id === user_problem.user_problem_id);
			if (index >= 0) {
				const user_set = problem_set_store.findUserSet({ user_set_id: user_problem.user_set_id,  });
				if (user_set == undefined) throw 'deleteUserProblem: returned undefined user set';

				const response = await api.delete(`courses/${course_id}/sets/${set_problem?.set_id ?? 0
				}/users/${user_set?.user_id}/problems/${user_problem.user_problem_id}`);
				if (response.status === 200) {
				// splice is used so vue3 reacts to changes.
					this.set_problems.splice(index, 1);
				} else {
					logger.error(JSON.stringify(response));
				}
			} else {
				logger.error('[stores/set_problems/deleteUserProblem]: the set problem was not found in the store');
			}
		}
	}
});

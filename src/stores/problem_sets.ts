import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { useSessionStore } from 'src/stores/session';

import { parseProblemSet, ProblemSet, ParseableProblemSet } from 'src/common/models/problem_sets';
import { MergedUserSet, ParseableMergedUserSet, parseMergedUserSet, UserSet } from 'src/common/models/user_sets';
import { LibraryProblem, SetProblem, ParseableProblem, parseProblem,
	ParseableSetProblem, UserProblem, MergedUserProblem, ParseableUserProblem,
	ParseableMergedUserProblem } from 'src/common/models/problems';
import { logger } from 'src/boot/logger';
import { ResponseError } from 'src/common/api-requests/interfaces';

export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
	set_problems: Array<SetProblem>;
	merged_user_sets: Array<MergedUserSet>;
	user_problems: Array<UserProblem>;
 	merged_user_problems: Array<MergedUserProblem>;
}

export const useProblemSetStore = defineStore('problem_sets', {
	state: (): ProblemSetState => ({
		problem_sets: [],
		set_problems: [],
		merged_user_sets: [],
		user_problems: [],
		merged_user_problems: []
	}),
	actions: {
		async fetchProblemSets(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/sets`);
			const sets_to_parse = response.data as Array<ParseableProblemSet>;
			logger.debug(`[problem_sets/fetchProblemSets] parsing response: ${sets_to_parse.join(', ')}`);
			this.problem_sets = sets_to_parse.map((set) => parseProblemSet(set));
		},
		async updateSet(set: ProblemSet): Promise<{ error: boolean; message: string }> {
			const course_id = useSessionStore().course.course_id;
			const response = await api.put(`courses/${course_id}/sets/${set.set_id}`, set.toObject());
			let message = '';
			let is_error = false;
			if (response.status === 200) {
				const updated_set = parseProblemSet(response.data as ParseableProblemSet);
				if (JSON.stringify(updated_set) !== JSON.stringify(set)) {
					logger.error('[updateSet] response does not match requested update to set');
				}
				message = `${updated_set.set_name} was successfully updated.`;
				const index = this.problem_sets.findIndex(s => s.set_id === set.set_id);
				this.problem_sets[index] = updated_set;
			} else {
				const error = response.data as ResponseError;
				message = error.message;
				is_error = true;
				logger.error(`Error updating set: ${message}`);
				// TODO: app-level error handling -- should throw here
			}

			return { error: is_error, message };

			// The following is not working.  TODO: fix-me
			// if (JSON.stringify(set) === JSON.stringify(_set)) {
			// commit('UPDATE_PROBLEM_SET', _set);
			// } else {
			// logger.error(`Problem set #${_set.set_id ?? 0} failed to update properly.`);
			// }

		},
		async fetchSetProblems(): Promise<void> {
			const course_id = useSessionStore().course.course_id;

			const response = await api.get(`courses/${course_id}/problems`);
			const all_problems = response.data as Array<ParseableProblem>;
			this.set_problems = all_problems.map((prob) => parseProblem(prob, 'Set') as SetProblem);
		},
		async addSetProblem(problem_info: { set_id: number, problem: LibraryProblem }): Promise<void> {
			const course_id = useSessionStore().course.course_id;

			const response = await api.post(`/courses/${course_id}/sets/${problem_info.set_id}/problems`, {
				problem_params: problem_info.problem.location_params.toObject()
			});
			const problem = response.data as ParseableSetProblem;
			// TODO: check for errors
			this.set_problems.push(new SetProblem(problem));
		},
		async updateSetProblem(params: { set_id: number, problem_id: number, props: ParseableProblem}): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const response = await api.put(`courses/${course_id}/sets/${params.set_id}/problems/${
				params.problem_id}`, params.props);
			const problem = response.data as ParseableSetProblem;
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === problem.problem_id);
			this.set_problems.splice(index, 1, parseProblem(problem, 'Set') as SetProblem);
		},
		async deleteSetProblem(problem: SetProblem): Promise<void> {
			const course_id = useSessionStore().course.course_id;

			const response = await api.delete(`courses/${course_id}/sets/${
				problem.set_id}/problems/${problem.problem_id}`);
			const deleted_problem = new SetProblem(response.data as ParseableSetProblem);
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === deleted_problem.problem_id);
			this.set_problems.splice(index, 1);
		},
		async fetchMergedUserSets(params: {course_id: number, set_id: number }): Promise<void> {
			const response = await api.get(`courses/${params.course_id}/sets/${params.set_id}/users`);
			const user_sets_to_parse = response.data as Array<ParseableMergedUserSet>;
			const user_sets = user_sets_to_parse.map(_set => parseMergedUserSet(_set));
			// TODO: check for errors
			this.merged_user_sets = [];
			user_sets.forEach(set => {
				if (set) {
					this.merged_user_sets.push(set);
				} else {
					logger.error('[stores/problem_sets/fetchMergedUserSets]: the set is not defined.');
				}
			});
		},
		async fetchCourseMergedUserSets(set_id: number): Promise<void> {
			const course_id = useSessionStore().course.course_id;

			const url = `courses/${course_id}/sets/${set_id}/users`;
			// console.log(url);
			const response = await api.get(url);
			const user_sets = response.data as Array<ParseableMergedUserSet>;

			// TODO: check for errors
			this.merged_user_sets = user_sets.map(_set => new MergedUserSet(_set));
		},
		async fetchUserMergedUserSets(user_id: number): Promise<void> {
			const course_id = useSessionStore().course.course_id;

			const url = `courses/${course_id}/users/${user_id}/sets`;
			const response = await api.get(url);
			const user_sets = response.data as Array<ParseableMergedUserSet>;
			// TODO: check for errors
		 	this.merged_user_sets = user_sets.map(_set => new MergedUserSet(_set));
		},
		async fetchUserProblems(user_id: number) {
			const course_id = useSessionStore().course.course_id;

			const url = `courses/${course_id}/users/${user_id}/problems`;
			const response = await api.get(url);
			const user_problems = response.data as Array<ParseableUserProblem>;
			// TODO: check for errors
			this.user_problems = user_problems.map(_problem => new UserProblem(_problem));
		},
		async fetchMergedUserProblems(user_id: number) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.get(`courses/${course_id}/users/${user_id}/problems?merged=true`);
			const user_problems = response.data as Array<ParseableMergedUserProblem>;
			// TODO: check for errors
			this.merged_user_problems = user_problems.map(_problem => new MergedUserProblem(_problem));
		},
		async addUserProblem(user_problem: UserProblem) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.post(`courses/${course_id}/users/${user_problem.user_id}/problem`);
			const new_user_problem = new UserProblem(response.data as ParseableUserProblem);
			this.user_problems.push(new_user_problem);
		},
		// This is the same as above, but adds a merged user problem to the store.
		async addMergedUserProblem(user_problem: UserProblem) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.post(`courses/${course_id}/users/${user_problem.user_id}/problem?merged=true`);
			const new_merged_user_problem = new MergedUserProblem(response.data as ParseableMergedUserProblem);
			this.merged_user_problems.push(new_merged_user_problem);
		},

		// This clears out all data for use during logout.
		clearAll(): void {
			this.problem_sets = [],
			this.set_problems = [];
			this.merged_user_sets = [];
			this.user_problems = [];
			this.merged_user_problems = [];
		},
		async addUserSet(user_set: UserSet) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.post(`courses/${course_id}/sets/${user_set.set_id}/users`, user_set.toObject());
			// TODO: check for errors
			const merged_user_set = parseMergedUserSet(response.data as ParseableMergedUserSet);
			if (merged_user_set) {
				this.merged_user_sets.push(merged_user_set);
			}

			// Add user problems for the given user set.
			const set_problems = this.set_problems.filter(prob => prob.set_id === merged_user_set?.set_id);
			for await (const prob of set_problems) {
				await this.addUserProblem(new UserProblem({
					user_id: merged_user_set?.user_set_id,
					problem_id: prob.problem_id,
					seed: Math.floor(10000 * Math.random())
				}));
			}
		},
		async updateUserSet(set: UserSet) {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const response = await api.put(`courses/${course_id}/sets/${set.set_id ?? 0}/users/${
				set.course_user_id ?? 0}`, set.toObject());
			const updated_user_set = new MergedUserSet(response.data as ParseableMergedUserSet);
			// TODO: check for errors
			const index = this.merged_user_sets.findIndex(s => s.set_id === updated_user_set.set_id);
			this.merged_user_sets.splice(index, 1, updated_user_set);
		},
		async deleteUserSet(user_set: UserSet) {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const response = await api.delete(`courses/${course_id}/sets/${user_set.set_id
			}/users/${user_set.course_user_id ?? 0}`);
			// TODO: check for errors
			const deleted_merged_user_set = new MergedUserSet(response.data as ParseableMergedUserSet);
			const index = this.merged_user_sets.findIndex(s => s.set_id === deleted_merged_user_set.set_id);
			this.merged_user_sets.splice(index, 1);
		},
	}
});

// This store is for problem sets, user sets, merged user sets and set problems.

import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { useSessionStore } from './session';
import { useUserStore } from './users';

import { parseProblemSet, ProblemSet, ParseableProblemSet } from 'src/common/models/problem_sets';
import { MergedUserSet, ParseableMergedUserSet, ParseableUserSet, parseMergedUserSet,
	parseUserSet, UserSet } from 'src/common/models/user_sets';
import { LibraryProblem, SetProblem, ParseableProblem, parseProblem,
	ParseableSetProblem } from 'src/common/models/problems';
import { logger } from 'src/boot/logger';
import { ResponseError } from 'src/common/api-requests/interfaces';

import { User } from 'src/common/models/users';

const user_store = useUserStore();
export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
	set_problems: Array<SetProblem>;
	user_sets: Array<UserSet>;
}

const createMergedUserSet = (user_set: UserSet, problem_set: ProblemSet, user: User) => {
	return new MergedUserSet({
		user_set_id: user_set.user_set_id,
		set_id: user_set.set_id,
		course_user_id: user_set.course_user_id,
		set_version: user_set.set_version,
		set_visible: user_set.set_visible,
		set_name: problem_set.set_name,
		username: user.username,
		set_type: problem_set.set_type,
		set_params: user_set.set_params,
		set_dates: user_set.set_dates
	});
};

export const useProblemSetStore = defineStore('problem_sets', {
	state: (): ProblemSetState => ({
		problem_sets: [],
		set_problems: [],
		user_sets: [],
	}),
	getters: {
		// Returns all user sets merged with a user and a problem set.
		merged_user_sets: (state) => state.user_sets.map(user_set => {
			const course_user = user_store.course_users.find(u => u.user_id === user_set.course_user_id);
			return createMergedUserSet(
				user_set as UserSet,
				state.problem_sets.find(set => set.set_id === user_set.set_id) as ProblemSet,
				(user_store.users.find(u => u.user_id === course_user?.user_id) as User) ??
					new User()
			);
		})
	},
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
		async fetchSetProblems(course_id: number): Promise<void> {
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
		async addUserSet(user_set: UserSet) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.post(`courses/${course_id}/sets/${user_set.set_id}/users`, user_set.toObject());
			// TODO: check for errors
			const merged_user_set = parseMergedUserSet(response.data as ParseableMergedUserSet);
			if (merged_user_set) {
				this.merged_user_sets.push(merged_user_set);
			}
		},
		async fetchUserSets(params: { course_id: number; set_id: number}) {
			const response = await api.get(`courses/${params.course_id}/sets/${params.set_id}/users`);
			const user_sets_to_parse = response.data as ParseableUserSet[];
			this.user_sets = user_sets_to_parse.map(user_set => parseUserSet(user_set));
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

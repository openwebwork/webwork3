import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { useSessionStore } from 'src/stores/session';

import { parseProblemSet, ProblemSet, ParseableProblemSet } from 'src/common/models/problem_sets';
import { MergedUserSet, ParseableMergedUserSet, parseMergedUserSet, UserSet } from 'src/common/models/user_sets';
import { LibraryProblem, SetProblem, ParseableProblem, parseProblem,
	ParseableSetProblem } from 'src/common/models/problems';
import { logger } from 'src/boot/logger';

export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
	set_problems: Array<SetProblem>;
	merged_user_sets: Array<MergedUserSet>;
}

export const useProblemSetStore = defineStore('problem_sets', {
	state: (): ProblemSetState => ({
		problem_sets: [],
		set_problems: [],
		merged_user_sets: []
	}),
	actions: {
		async fetchProblemSets(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/sets`);
			const sets_to_parse = response.data as Array<ParseableProblemSet>;
			this.problem_sets = sets_to_parse.map((set) => parseProblemSet(set));
		},
		async updateSet(set: ProblemSet): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;
			// shouldn't we be throwing an error if set_id is null or 0?
			const response = await api.put(`courses/${course_id}/sets/${set.set_id ?? 0}`, set.toObject());
			const updated_set = parseProblemSet(response.data as ParseableProblemSet);
			const index = this.problem_sets.findIndex(s => s.set_id === set.set_id);

			// The following is not working.  TODO: fix-me
			// if (JSON.stringify(set) === JSON.stringify(_set)) {
			// commit('UPDATE_PROBLEM_SET', _set);
			// } else {
			// logger.error(`Problem set #${_set.set_id ?? 0} failed to update properly.`);
			// }

			this.problem_sets[index] = updated_set;
		},
		async fetchSetProblems(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/problems`);
			const all_problems = response.data as Array<ParseableProblem>;
			this.set_problems = all_problems.map((prob) => parseProblem(prob, 'Set') as SetProblem);
		},
		async addSetProblem(problem_info: { set_id: number, problem: LibraryProblem }): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `/courses/${course_id}/sets/${problem_info.set_id}/problems`;
			const response = await api.post(url, {
				problem_params: problem_info.problem.location_params.toObject()
			});
			const problem = response.data as ParseableSetProblem;
			// TODO: check for errors
			this.set_problems.push(new SetProblem(problem));
		},
		async updateSetProblem(params: { set_id: number, problem_id: number, props: ParseableProblem}): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `courses/${course_id}/sets/${params.set_id}/problems/${params.problem_id ?? 0}`;
			const response = await api.put(url, params.props);
			const problem = response.data as ParseableSetProblem;
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === problem.problem_id);
			this.set_problems.splice(index, 1, parseProblem(problem, 'Set') as SetProblem);
		},
		async deleteSetProblem(problem: SetProblem): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `courses/${course_id}/sets/${problem.set_id ?? 0}/problems/${problem.problem_id ?? 0}`;
			const response = await api.delete(url);
			const deleted_problem = new SetProblem(response.data as ParseableSetProblem);
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === deleted_problem.problem_id);
			this.set_problems.splice(index, 1);
		},
		async fetchMergedUserSets(params: {course_id: number, set_id: number }): Promise<void> {
			const url = `courses/${params.course_id}/sets/${params.set_id}/users`;
			const response = await api.get(url);
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
		async addUserSet(user_set: UserSet) {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `courses/${course_id}/sets/${user_set.set_id ?? 0}/users`;
			const response = await api.post(url, user_set.toObject());
			// TODO: check for errors
			const merged_user_set = parseMergedUserSet(response.data as ParseableMergedUserSet);
			if (merged_user_set) {
				this.merged_user_sets.push(merged_user_set);
			}
		},
		async updateUserSet(set: UserSet) {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `courses/${course_id}/sets/${set.set_id ?? 0}/users/${set.course_user_id ?? 0}`;
			const response = await api.put(url, set.toObject());
			const updated_user_set = new MergedUserSet(response.data as ParseableMergedUserSet);
			// TODO: check for errors
			const index = this.merged_user_sets.findIndex(s => s.set_id === updated_user_set.set_id);
			this.merged_user_sets.splice(index, 1, updated_user_set);
		},
		async deleteUserSet(user_set: UserSet) {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const url = `courses/${course_id}/sets/${user_set.set_id ?? 0}/users/${user_set.course_user_id ?? 0}`;
			const response = await api.delete(url);
			// TODO: check for errors
			const deleted_merged_user_set = new MergedUserSet(response.data as ParseableMergedUserSet);
			const index = this.merged_user_sets.findIndex(s => s.set_id === deleted_merged_user_set.set_id);
			this.merged_user_sets.splice(index, 1);
		},
	}
});

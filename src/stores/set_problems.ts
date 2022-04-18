// This store handles set problems and user problems.

import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { ParseableProblem, parseProblem, SetProblem, LibraryProblem, ParseableSetProblem,
	UserProblem, ParseableUserProblem } from 'src/common/models/problems';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from './problem_sets';

export interface SetProblemsState {
	set_problems: SetProblem[];
	user_problems: UserProblem[];
}

export const useSetProblemStore = defineStore('set_problems', {

	state: (): SetProblemsState => ({
		set_problems: [],
		user_problems: []
	}),

	getters: {
		// Return the set problems with a given set_id or set_name.
		findSetProblems: (state) => (set_info: {set_id?: number; set_name?: string }): SetProblem[] => {
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
		// Note: using standard function notation (not arrow) due to using this.
		// Return the user problems with a given set_id, set_name
		findUserProblems(state) {
			return (set_info: {set_id?: number, set_name?: string }) => {
			// get a list of the desired problem_ids

				const problem_ids = this.findSetProblems(set_info).map(prob => prob.problem_id);
				return state.user_problems
					.filter(user_prob => problem_ids.findIndex(prob_id => user_prob.problem_id === prob_id) >= 0);
			};
		},
		// merged_user_problems: (state) => (user_info: { user_id?: number; username?: string}) =>
		// []
	},
	actions: {
		// Fetch Set Problems for a given course.
		async fetchSetProblems(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/problems`);
			const all_problems = response.data as Array<ParseableProblem>;
			this.set_problems = all_problems.map((prob) => parseProblem(prob, 'Set') as SetProblem);
		},
		async addSetProblem(problem_info: { set_id: number, problem: LibraryProblem }): Promise<SetProblem> {
			const course_id = useSessionStore().course.course_id;

			const response = await api.post(`/courses/${course_id}/sets/${problem_info.set_id}/problems`, {
				problem_params: problem_info.problem.location_params.toObject()
			});

			// TODO: check for errors
			const new_problem = new SetProblem(response.data as ParseableSetProblem);
			this.set_problems.push(new_problem);
			return new_problem;
		},
		async updateSetProblem(params: { set_id: number, problem_id: number, props: ParseableSetProblem}):
			Promise<SetProblem> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const response = await api.put(`courses/${course_id}/sets/${params.set_id}/problems/${
				params.problem_id}`, params.props);
			const updated_problem = new SetProblem(response.data as ParseableSetProblem);
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === updated_problem.problem_id);
			this.set_problems.splice(index, 1, updated_problem);
			return updated_problem;
		},
		async deleteSetProblem(problem: SetProblem): Promise<SetProblem> {
			const course_id = useSessionStore().course.course_id;

			const response = await api.delete(`courses/${course_id}/sets/${
				problem.set_id}/problems/${problem.problem_id}`);
			const deleted_problem = new SetProblem(response.data as ParseableSetProblem);
			// TODO: check for errors
			const index = this.set_problems.findIndex(prob => prob.problem_id === deleted_problem.problem_id);
			this.set_problems.splice(index, 1);
			return deleted_problem;
		},
		// UserProblem actions
		// Fetch all user problems for a set in a course.
		async fetchUserProblems(set_id: number) {
			const course_id = useSessionStore().course.course_id;
			const response = await api.get(`courses/${course_id}/sets/${set_id}/user-problems`);
			this.user_problems = (response.data as ParseableUserProblem[]).map(prob => new UserProblem(prob));
		},
		async addUserProblem(user_problem: UserProblem): Promise<UserProblem> {
			const course_id = useSessionStore().course.course_id;
			const set_problem = this.set_problems.find(prob => prob.problem_id === user_problem.problem_id);
			const problem_set_store = useProblemSetStore();
			const user_set = problem_set_store.findMergedUserSet({ user_set_id: user_problem.user_set_id });
			// TODO: handle if either set_problem or user_set undefined.

			const user_problem_params = user_problem.toObject();
			// The render params are not stored in the DB.
			delete user_problem_params.render_params;
			const response = await api.post(`courses/${course_id}/sets/${set_problem?.set_id ?? 0}/users/${
				user_set?.user_id ?? 0}/problems`, user_problem_params);
			const added_user_problem = new UserProblem(response.data as ParseableUserProblem);
			this.user_problems.push(added_user_problem);
			return added_user_problem;
		},
		async deleteUserProblem(user_problem: UserProblem): Promise<UserProblem> {
			const course_id = useSessionStore().course.course_id;
			const set_problem = this.set_problems.find(prob => prob.problem_id === user_problem.problem_id);
			const problem_set_store = useProblemSetStore();
			const user_set = problem_set_store.findMergedUserSet({ user_set_id: user_problem.user_set_id,  });

			// handle if undefined.
			const response = await api.delete(`courses/${course_id}/sets/${set_problem?.set_id ?? 0
			}/users/${user_set.user_id}/problems/${user_problem.problem_id}`);
			const deleted_problem = new UserProblem(response.data as ParseableUserProblem);
			const index = this.user_problems
				.findIndex(user_problem => user_problem.user_problem_id === deleted_problem.user_problem_id);
			if (index >= 0) {
				this.user_problems.splice(index, 1);
			}
			return deleted_problem;
		}
	}
});

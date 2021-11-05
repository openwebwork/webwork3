import { api } from '@/boot/axios';
import { Commit } from 'vuex';
import { StateInterface } from '@/store';
import { isEqual } from 'lodash-es';

import { parseProblemSet, ProblemSet, ParseableProblemSet } from '@/store/models/problem_sets';
import { LibraryProblem, ParseableLibraryProblem } from '@/store/models/library';

export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
	problems: Array<LibraryProblem>;
}

const initial_state = {
	problem_sets: [],
	problems: []
};

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		problem_sets(state: ProblemSetState): Array<ProblemSet> {
			return state.problem_sets;
		},
		problems(state: ProblemSetState): Array<LibraryProblem> {
			return state.problems;
		}
	},
	actions: {
		async fetchProblemSets({ commit }: { commit: Commit }, course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/sets`);
			const _sets_to_parse = response.data as Array<ParseableProblemSet>;
			commit('SET_PROBLEM_SETS', _sets_to_parse.map((set)=> parseProblemSet(set)));
		},
		async updateSet({ commit, rootState }: { commit: Commit; rootState: StateInterface },
			 _set: ProblemSet): Promise<ProblemSet> {
			const course_id = rootState.session.course.course_id;
			const response = await api.put(`courses/${course_id}/sets/${_set.set_id ?? 0}`, _set);
			const set = response.data as ProblemSet;
			if (isEqual(set, _set)) {
				commit('UPDATE_PROBLEM_SET', _set);
			} else {
				// console.error('The returned set is not the same. ');
			}
			return set;
		},
		async fetchSetProblems({ commit }: { commit: Commit }, course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/problems`);
			const all_problems = response.data as Array<ParseableLibraryProblem>;
			commit('SET_PROBLEMS', all_problems.map((prob)=> new LibraryProblem(prob)));
		},
		async addSetProblem({ commit }: { commit: Commit },
			problem_info: { course_id: number, problem: LibraryProblem }): Promise<void> {
			const url = `/courses/${problem_info.course_id}/sets/${problem_info.problem.set_id ?? 0}/problems`;
			const response = await api.post(url, problem_info.problem);
			const problem = response.data as LibraryProblem;
			// TODO: check for errors
			commit('ADD_SET_PROBLEM', problem);
		},
		async updateSetProblem({ commit, rootState }: { commit: Commit; rootState: StateInterface },
			params: { prob: LibraryProblem, props: ParseableLibraryProblem}): Promise<void> {
			const course_id = rootState.session.course.course_id;
			const url = `courses/${course_id}/sets/${params.prob.set_id ?? 0}/problems/${params.prob.problem_id ?? 0}`;
			const response = await api.put(url, params.props);
			const problem = response.data as LibraryProblem;
			// TODO: check for errors
			commit('UPDATE_SET_PROBLEM', problem);
		}
	},
	mutations: {
		SET_PROBLEM_SETS(state: ProblemSetState, _problem_sets: Array<ProblemSet>): void {
			state.problem_sets = _problem_sets;
		},
		UPDATE_PROBLEM_SET(state: ProblemSetState, _set: ProblemSet): void {
			const index = state.problem_sets.findIndex((s: ProblemSet) => s.set_id === _set.set_id);
			state.problem_sets[index] = _set;
		},
		SET_PROBLEMS(state: ProblemSetState, _set_problems: Array<LibraryProblem>): void {
			state.problems = _set_problems;
		},
		ADD_SET_PROBLEM(state: ProblemSetState, _problem: LibraryProblem): void {
			state.problems.push(_problem);
		},
		UPDATE_SET_PROBLEM(state: ProblemSetState, _problem: LibraryProblem): void {
			const index = state.problems.findIndex(prob => prob.problem_id === _problem.problem_id);
			state.problems[index] = _problem;
		}
	}
};

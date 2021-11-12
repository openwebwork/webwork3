/* eslint-disable no-tabs */
import { api } from '@/boot/axios';
import { Commit } from 'vuex';
// import { StateInterface } from '../index';
// import { isEqual } from 'lodash-es';

import { Problem, ParseableProblem, parseProblem } from '@/store/models/set_problem';

export interface SetProblemsState {
	problems: Array<Problem>;
}

const initial_state = {
	problems: []
};

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		problem_sets(state: SetProblemsState): Array<Problem> {
			return state.problems;
		}
	},
	actions: {
		async fetchSetProblems({ commit }: { commit: Commit }, course_id: number, set_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/sets/${set_id}/problems`);
			const _sets_to_parse = response.data as Array<ParseableProblem>;
			commit('SET_SET_PROBLEMS)', _sets_to_parse.map((problem)=> parseProblem(problem, 'Set')));
		},
		// async updateSet(
		// 	{ commit, rootState }: { commit: Commit; rootState: StateInterface },
		// 	 _set: SetProblem): Promise<SetProblem> {
		// 	const course_id = rootState.session.course.course_id;
		// 	// shouldn't we be throwing an error if set_id is null or 0?
		// 	const response = await api.put(`courses/${course_id}/sets/${_set.set_id ?? 0}`, _set);
		// 	const set = response.data as SetProblem;
		// 	if (isEqual(set, _set)) {
		// 		commit('UPDATE_PROBLEM_SET', _set);
		// 	} else {
		// 		logger.error(`Problem set #${_set.set_id ?? 0} failed to update properly.`);
		// 	}
		// 	return set;
		// }
	},
	mutations: {
		SET_SET_PROBLEMS(state: SetProblemsState, _set_problems: Array<Problem>): void {
			state.problems = _set_problems;
		},
		// UPDATE_PROBLEM_SET(state: SetProblemsState, _set: SetProblem): void {
		// 	const index = state.problem_sets.findIndex((s: SetProblem) => s.set_id === _set.set_id);
		// 	state.problem_sets[index] = _set;
		// }
	}
};

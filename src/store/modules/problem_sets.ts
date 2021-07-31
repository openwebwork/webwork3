import axios from 'axios';
import { Commit } from 'vuex';

import { ProblemSet } from '../models';


export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
}

const initial_state = {
	problem_sets: []
}

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		problem_sets(state: ProblemSetState): Array<ProblemSet> {
			return state.problem_sets
		}
	},
  actions: {
		async fetchProblemSets({ commit }: { commit: Commit },course_id: number): Promise<void> {
			const _problem_sets = await _fetchProblemSets(course_id);
			commit('SET_PROBLEM_SETS',_problem_sets);
		},
	},
  mutations: {
		SET_PROBLEM_SETS(state: ProblemSetState, _problem_sets: Array<ProblemSet>): void {
			state.problem_sets = _problem_sets;
		}
	}
};

async function _fetchProblemSets(course_id: number): Promise<Array<ProblemSet>> {
	const response = await axios.get(`/webwork3/api/courses/${course_id}/sets`);
	// eslint-disable-next-line
	return (response.data.exception) ? [] : (response.data as Array<ProblemSet>);
}
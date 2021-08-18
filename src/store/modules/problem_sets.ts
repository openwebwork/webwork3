import axios from 'axios';
import { Commit } from 'vuex';
import { StateInterface } from '../index';

import { ProblemSet } from 'src/store/models';

export interface ProblemSetState {
	problem_sets: Array<ProblemSet>;
}

const initial_state = {
	problem_sets: []
};

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		problem_sets(state: ProblemSetState): Array<ProblemSet> {
			return state.problem_sets;
		}
	},
	actions: {
		async fetchProblemSets({ commit }: { commit: Commit }, course_id: number): Promise<void> {
			const _problem_sets = await _fetchProblemSets(course_id);

			commit('SET_PROBLEM_SETS', _problem_sets);
		},
		async updateSet(
			{ commit, rootState }: { commit: Commit; rootState: StateInterface },
			 _set: ProblemSet): Promise<ProblemSet> {
			const course_id = rootState.session.course.course_id;
			const url = `${process.env.VUE_ROUTER_BASE ?? ''}api/courses/${course_id}/sets/${_set.set_id}`;
			const response = await axios.put(url, _set);
			commit('UPDATE_PROBLEM_SET', _set);
			return response.data as ProblemSet;
		}
	},
	mutations: {
		SET_PROBLEM_SETS(state: ProblemSetState, _problem_sets: Array<ProblemSet>): void {
			state.problem_sets = _problem_sets;
		},
		UPDATE_PROBLEM_SET(state: ProblemSetState, _set: ProblemSet): void {
			console.log('in UPDATE_PROBLEM_SET');
			const index = state.problem_sets.findIndex((s: ProblemSet) => s.set_id === _set.set_id);
			state.problem_sets[index] = _set;
		}
	}
};

async function _fetchProblemSets(course_id: number): Promise<Array<ProblemSet>> {
	const response = await axios.get(`${process.env.VUE_ROUTER_BASE ?? ''}api/courses/${course_id}/sets`);
	// eslint-disable-next-line
	return (response.data.exception) ? [] : (response.data as Array<ProblemSet>);
}

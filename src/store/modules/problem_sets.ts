import { api } from 'boot/axios';
import { Commit } from 'vuex';
import { StateInterface } from '../index';
import { isEqual } from 'lodash-es';

import { ProblemSet, ParseableProblemSet, parseProblemSet } from 'src/store/models';

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
			const response = await api.get(`courses/${course_id}/sets`);
			const _sets_to_parse = response.data as Array<ParseableProblemSet>;
			console.log(_sets_to_parse);
			commit('SET_PROBLEM_SETS', _sets_to_parse.map((set)=> parseProblemSet(set)));
		},
		async updateSet(
			{ commit, rootState }: { commit: Commit; rootState: StateInterface },
			 _set: ProblemSet): Promise<ProblemSet> {
			const course_id = rootState.session.course.course_id;
			const response = await api.put(`courses/${course_id}/sets/${_set.set_id}`, _set);
			const set = response.data as ProblemSet;
			if (isEqual(set, _set)) {
				commit('UPDATE_PROBLEM_SET', _set);
			} else {
				// console.error('The returned set is not the same. ');
			}
			return set;
		}
	},
	mutations: {
		SET_PROBLEM_SETS(state: ProblemSetState, _problem_sets: Array<ProblemSet>): void {
			state.problem_sets = _problem_sets;
		},
		UPDATE_PROBLEM_SET(state: ProblemSetState, _set: ProblemSet): void {
			const index = state.problem_sets.findIndex((s: ProblemSet) => s.set_id === _set.set_id);
			state.problem_sets[index] = _set;
		}
	}
};

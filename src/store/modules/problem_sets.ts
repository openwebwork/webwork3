import axios from 'axios';
import { Commit } from 'vuex';
import { StateInterface } from '../index';
import { isEqual } from 'lodash';

import { ProblemSet, ParseableProblemSet } from 'src/store/models';
import { parseHW, parseQuiz } from '../common';

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
			const set = response.data as ProblemSet;
			if (isEqual(set, _set)) {
				commit('UPDATE_PROBLEM_SET', _set);
			} else {
				console.error('The returned set is not the same. ');
				console.log(set);
				console.log(_set);
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

async function _fetchProblemSets(course_id: number): Promise<Array<ProblemSet>> {
	const response = await axios.get(`${process.env.VUE_ROUTER_BASE ?? ''}api/courses/${course_id}/sets`);
	// eslint-disable-next-line
	if (response.data.exception) {
		console.error(response.data);
	}
	const all_sets = response.data as Array<ParseableProblemSet>;
	const problem_sets: Array<ProblemSet> = [];
	all_sets.forEach((_set: ParseableProblemSet) => {
		if (_set.set_type === 'HW') {
			problem_sets.push(parseHW(_set));
		} else if (_set.set_type === 'QUIZ') {
			problem_sets.push(parseQuiz(_set));
		} else {
			console.error('Unexpected Problem type: ');
			console.error(_set);
		}
	});

	return problem_sets;

}

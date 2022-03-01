import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { Problem, ParseableProblem, parseProblem } from 'src/common/models/problems';
import { useSessionStore } from 'src/stores/session';

export interface SetProblemsState {
	set_problems: Array<Problem>;
}

export const useSetProblemStore = defineStore('set_problems', {

	state: (): SetProblemsState => ({
		set_problems: []
	}),
	actions: {
		async fetchSetProblems(set_id: number): Promise<void> {
			const sessionStore = useSessionStore();
			const course_id = sessionStore.course.course_id;

			const response = await api.get(`courses/${course_id}/sets/${set_id}/problems`);
			const sets_to_parse = response.data as Array<ParseableProblem>;
			this.set_problems =  sets_to_parse.map((problem) => parseProblem(problem, 'Set'));
		},
		/* eslint-disable no-tabs */
		// async updateSet(
		// 	{ commit, rootState }: { commit: Commit; rootState: StateInterface },
		// 	 _set: SetProblem): Promise<SetProblem> {
		// 	const course_id = rootState.session.course.course_id;
		// 	// shouldn't we be throwing an error if set_id is null or 0?
		// 	const response = await api.put(`courses/${course_id}/sets/${_set.set_id ?? 0}`, _set);
		// 	const set = response.data as SetProblem;
		// 	if (JSON.stringify(set) === JSON.stringify(_set))) {
		// 		commit('UPDATE_PROBLEM_SET', _set);
		// 	} else {
		// 		logger.error(`Problem set #${_set.set_id ?? 0} failed to update properly.`);
		// 	}
		// 	return set;
		// }
		/* eslint-enable */
	}
});

/* This module stores some information about the state of the app */

import { Commit } from 'vuex';

interface LibraryState {
	target_set_id: number;
}

export interface AppState {
	library_state: LibraryState;
}

const initial_state = {
	library_state: {
		target_set_id: 0
	}
};

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		target_set_id(state: AppState): number {
			return state.library_state.target_set_id;
		}
		// courses(state: CourseState): Array<Course> {
		// return state.courses;
		// }
	},
	actions: {
		setTargetSetID({ commit }: { commit: Commit }, _target_set_id: number): void {
			commit('SET_TARGET_SET_ID', _target_set_id);
		}
	},
	mutations: {
		SET_TARGET_SET_ID(state: AppState, _target_set_id: number): void {
			console.log(_target_set_id);
			state.library_state.target_set_id = _target_set_id;
		}
	}
};

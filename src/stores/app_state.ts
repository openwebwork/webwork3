/* This module stores some information about the state of the app */

import { defineStore } from 'pinia';

interface LibraryState {
	target_set_id: number;
}

export interface AppState {
	library_state: LibraryState;
}

export const useAppStateStore = defineStore('app_state', {
	state: (): AppState => ({
		library_state: {
			target_set_id: 0
		}
	}),
	getters: {
		target_set_id(): number {
			return this.library_state.target_set_id;
		}
	},
	actions: {
		setTargetSetID(target_set_id: number): void {
			this.library_state.target_set_id = target_set_id;
		}
	}
});

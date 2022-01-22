import { store } from 'quasar/wrappers';
import { InjectionKey } from 'vue';
import { createStore, Store as VuexStore, useStore as vuexUseStore } from 'vuex';
import createPersistedState from 'vuex-persistedstate';

import session, { SessionState } from './modules/session';
import users, { UserState } from './modules/users';
import settings, { SettingsState } from './modules/settings';
import problem_sets, { ProblemSetState } from './modules/problem_sets';
import courses, { CourseState } from './modules/courses';
import app_state, { AppState } from './modules/app_state';

export interface StateInterface {
	// Define your own store structure, using submodules if needed
	// example: ExampleStateInterface;
	// Declared as unknown to avoid linting issue. Best to strongly type as per the line above.
	session: SessionState;
	users: UserState;
	settings: SettingsState;
	problem_sets: ProblemSetState;
	courses: CourseState;
	app_state: AppState;
}

// provide typings for `this.$store`
declare module '@vue/runtime-core' {
	interface ComponentCustomProperties {
		$store: VuexStore<StateInterface>;
	}
}

// provide typings for `useStore` helper
export const storeKey: InjectionKey<VuexStore<StateInterface>> = Symbol('vuex-key');

export default store(function () {
	const Store = createStore<StateInterface>({
		modules: {
			session,
			users,
			settings,
			problem_sets,
			courses,
			app_state
		},

		// Save the current state to session storage
		plugins: [createPersistedState({ storage: window.sessionStorage })],

		// enable strict mode (adds overhead!)
		// for dev mode and --debug builds only
		strict: !!process.env.DEBUGGING
	});

	return Store;
});

export function useStore() {
	return vuexUseStore(storeKey);
}

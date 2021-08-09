import { Module, ActionTree, GetterTree, MutationTree } from 'vuex';
import { StateInterface } from 'src/store';
// import state, { SessionState } from './state';
// import actions from './actions';
// import getters from './getters';
// import mutations from './mutations';

export interface SessionState {
	logged_in: boolean;
	user: string;
	course_name: string;
}

function state(): SessionState {
	return {
		logged_in: false,
		user: '',
		course_name: ''
	};
}

const getters: GetterTree<SessionState, StateInterface> = {
	someAction (/* context */) {
		// your code
	}
};

const actions: ActionTree<SessionState, StateInterface> = {
	someAction (/* context */) {
		// your code
	}
};

const mutations: MutationTree<SessionState> = {
	someMutation (/* state: ExampleStateInterface */) {
		// your code
	}
};

const exampleModule: Module<SessionState, StateInterface> = {
	namespaced: true,
	actions,
	getters,
	mutations,
	state
};

export default exampleModule;

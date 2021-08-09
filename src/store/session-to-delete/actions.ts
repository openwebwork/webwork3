import { ActionTree } from 'vuex';
import { StateInterface } from 'src/store';
import { SessionState } from './state';

const actions: ActionTree<SessionState, StateInterface> = {
	someAction (/* context */) {
		// your code
	}
};

export default actions;

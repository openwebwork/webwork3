import { ActionTree } from 'vuex';
import { StateInterface } from '../index';
import { SessionState } from './state';

const actions: ActionTree<SessionState, StateInterface> = {
  someAction (/* context */) {
    // your code
  }
};

export default actions;

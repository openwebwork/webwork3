import { GetterTree } from 'vuex';
import { StateInterface } from '../index';
import { SessionState } from './state';

const getters: GetterTree<SessionState, StateInterface> = {
  someAction (/* context */) {
    // your code
  }
};

export default getters;

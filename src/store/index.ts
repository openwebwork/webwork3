import { createStore } from 'vuex';

import { sessionModule } from "./modules/session";
import { userModule } from './modules/user';

export default createStore({
  modules: {
    session: sessionModule,
		user: userModule
  },
});
import { createApp } from 'vue'
import App from './App.vue'
import { Quasar } from 'quasar'
import quasarUserOptions from './quasar-user-options'

import router from "@/router";
import store from "@/store";

const app = createApp(App)
	.use(Quasar, quasarUserOptions)
	.use(router)
	.use(store);

router.isReady().then(() => app.mount('#app'))


// eslint-disable-next-line @typescript-eslint/no-unused-vars
router.beforeEach( (to, from) => {
	// need to check for allowed access here.

	if (to.params.course_name) {
		store.dispatch('session/setCourseName',to.params.course_name);
	}
});
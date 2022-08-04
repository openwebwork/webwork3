import { route } from 'quasar/wrappers';
import { logger } from 'src/boot/logger';
import { usePermissionStore } from 'src/stores/permissions';
import { useSessionStore } from 'src/stores/session';
import { createMemoryHistory, createRouter, createWebHashHistory, createWebHistory } from 'vue-router';
import routes from './routes';

/*
 * If not building with SSR mode, you can
 * directly export the Router instantiation;
 *
 * The function below can be async too; either use
 * async/await or return a Promise which resolves
 * with the Router instance.
 */

export default route(() => {
	const createHistory = process.env.SERVER
		? createMemoryHistory
		: (process.env.VUE_ROUTER_MODE === 'history' ? createWebHistory : createWebHashHistory);

	const router = createRouter({
		scrollBehavior: () => ({ left: 0, top: 0 }),
		routes,

		// Leave this as is and make changes in quasar.conf.js instead!
		// quasar.conf.js -> build -> vueRouterMode
		// quasar.conf.js -> build -> publicPath
		history: createHistory(
			process.env.MODE === 'ssr' ? void 0 : process.env.VUE_ROUTER_BASE
		),
	});

	router.beforeResolve((to) => {
		// must be logged in, or else headed to the login page
		const session_store = useSessionStore();
		if (!session_store.logged_in && to.name !== 'login') return { name: 'login' };

		// otherwise, we're logged in, so check permissions on the route
		const permissions_store = usePermissionStore();
		const perm = permissions_store.hasRoutePermission(to);
		if (!perm) {
			const user = session_store.getUser;
			logger.error(`[routing] User #${user.user_id} does not have the permission to visit ${to.fullPath}`);
			return { name: 'user_courses', params: { user_id: user.user_id } };
		}
	});

	return router;
});

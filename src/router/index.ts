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
		const session_store = useSessionStore();

		// Redirect to the login page if user is not authenticated
		if (!session_store.authIsCurrent() && to.name !== 'login') {
			localStorage.setItem('afterLogin', to.path);
			return { name: 'login' };
		};

		// user is logged in, so check permissions on the route
		const permissions_store = usePermissionStore();
		if (!permissions_store.hasRoutePermission(to)) {
			const user = session_store.getUser;
			logger.warn(`[routing] User #${user.user_id} does not have the permission to visit ${to.fullPath}`);
			return { name: 'user_courses', params: { user_id: user.user_id } };
		}
	});

	return router;
});

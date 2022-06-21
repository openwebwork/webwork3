import { route } from 'quasar/wrappers';
import { logger } from 'src/boot/logger';
import { usePermissionStore } from 'src/stores/permissions';
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

	router.beforeEach((to, _from, next) => {
		if (to.path === '/login') next();
		const permissions_store = usePermissionStore();
		const perm = permissions_store.hasRoutePermission(to.path);
		console.log(to);
		console.log(perm);
		if (!perm) {
			logger.error(`[routing] The user does not have the permission to visit ${to.path}`);
		}
		next();
	});

	return router;
});

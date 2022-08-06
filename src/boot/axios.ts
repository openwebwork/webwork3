import { boot } from 'quasar/wrappers';
import axios, { AxiosInstance } from 'axios';
import { useSessionStore } from 'src/stores/session';

declare module '@vue/runtime-core' {
	interface ComponentCustomProperties {
		$axios: AxiosInstance;
	}
}

// Be careful when using SSR for cross-request state pollution
// due to creating a Singleton instance here;
// If any client changes this (global) instance, it might be a
// good idea to move this instance creation inside of the
// "export default () => {}" function below (which runs individually
// for each client)

const api = axios.create({ baseURL: (process.env.VUE_ROUTER_BASE ?? '') + 'api' });

api.interceptors.response.use((response) => {
	const session = useSessionStore();
	// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
	const expiry = response.headers['x-expiry'] as number ?? 0;
	session.updateExpiry(expiry * 1000);
	return response;
});

export default boot(({ app }) => {
	// for use inside Vue files (Options API) through this.$axios and this.$api

	app.config.globalProperties.$axios = axios;
	// ^ ^ ^ this will allow you to use this.$axios (for Vue Options API form)
	//       so you won't necessarily have to import axios in each vue file

	app.config.globalProperties.$api = api;
	// ^ ^ ^ this will allow you to use this.$api (for Vue Options API form)
	//       so you can easily perform requests against your app's API
});

export { api };

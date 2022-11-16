/** @jest-environment jsdom */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// Test the Course Store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { usePermissionStore } from 'src/stores/permissions';

describe('Test the permissions store', () => {

	const app = createApp({});

	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as the admin in order to be authenticated for the rest of the test.
		await api.post('login', { username: 'admin', password: 'admin' });

	});

	test('Check the roles', async () => {
		const permissions_store = usePermissionStore();
		const defined_roles = ['course_admin', 'instructor', 'ta', 'student'];
		await permissions_store.fetchRoles();

		expect(defined_roles.sort()).toStrictEqual(permissions_store.roles.sort());

		expect(permissions_store.isValidRole('instructor')).toBe(true);
		expect(permissions_store.isValidRole('superhero')).toBe(false);
	});

	const routeCompare = (route1: { route: string}, route2: { route: string }) =>
		route1.route > route2.route ? 1 : -1;

	test('Load the UI route permissions', async () => {
		const permissions_store = usePermissionStore();
		await permissions_store.fetchRoutePermissions();

		// the route permissions.  Perhaps better to load from yaml file.
		const route_permissions = [
			{
				route: '/login',
				allowed_roles: ['*'],
				admin_required: false,
				allow_self_access: false,
			},
			{
				route: '/users/*/courses',
				allowed_roles: ['instructor', 'course_admin'],
				admin_required: false,
				allow_self_access: true
			},
			{
				route: '/courses/*/instructor',
				allowed_roles: ['instructor', 'course_admin'],
				admin_required: false,
				allow_self_access: false,
			},
			{
				route: '/courses/*/student',
				allowed_roles: ['student', 'instructor', 'course_admin'],
				admin_required: false,
				allow_self_access: false,
			},
			{
				route: '/admin',
				admin_required: true,
				allowed_roles: [],
				allow_self_access: false,
			}
		];

		expect(permissions_store.ui_permissions.sort(routeCompare))
			.toStrictEqual(route_permissions.sort(routeCompare));

	});

});

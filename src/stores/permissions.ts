// Permission store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';
import { useSessionStore } from './session';
import { RouteLocationNormalized } from 'vue-router';
import { parseRouteUserID } from 'src/router/utils';

export type UserRole = string;

interface UIPermission {
	route: string;
	allowed_roles: UserRole[];
	admin_required: boolean;
	allow_self_access?: boolean;
}

export interface PermissionsState {
	roles: UserRole[];
	ui_permissions: UIPermission[];
}

export const usePermissionStore = defineStore('permission', {
	persist: true,
	state: (): PermissionsState => ({
		roles: [],
		ui_permissions: []
	}),
	getters: {
		/**
		 * Determines if the passed in string is a valid role.
		 */
		isValidRole: (state) => (role: string): boolean  => state.roles.includes(role.toUpperCase()),

		/**
		 * Determines if the current user (from the session store) has permission for the given route.
		 */
		hasRoutePermission: (state) => (route: RouteLocationNormalized): boolean => {
			const session_store = useSessionStore();
			const role = session_store.course.role ?? '';
			const user = session_store.user;
			const perms = state.ui_permissions.filter(perm => {
				const re = new RegExp(perm.route.replace('*', '.*?'));
				return re.test(route.path);
			});

			// Find the longest matched route
			const permission = perms.reduce((prev, curr) => prev.route.length > curr.route.length ? prev : curr,
				{ route: '', allowed_roles: [], admin_required: false });

			if (permission.allowed_roles.length === 1 && permission.allowed_roles[0] === '*') return true;
			// Some routes have self-access:
			if (permission.allow_self_access) {
				const user_id = parseRouteUserID(route);
				if (user_id === user.user_id) return true;
			}
			return permission.allowed_roles.includes(role);
		}
	},
	actions: {
		async fetchRoles(): Promise<void> {
			const response = await api.get('roles/');
			this.roles = (response.data as string[]).map(role => role.toUpperCase());
		},
		async fetchRoutePermissions(): Promise<void> {
			const response = await api.get('ui-permissions/');
			const perms = response.data as UIPermission[];

			this.ui_permissions = perms.map(p => ({
				allowed_roles: p.allowed_roles.map(r => r.toUpperCase()),
				route: p.route,
				// This can be updated when the server sends back true/false.
				admin_required: p.admin_required ?? false,
				allow_self_access: p.allow_self_access ?? false
			}));
		}
	}
});

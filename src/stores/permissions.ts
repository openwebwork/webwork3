// Permission store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';

export type UserRole = string;

interface UIPermission {
	route: string;
	allowed_roles: UserRole[];
	admin_required: boolean;
}

export interface PermissionsState {
	roles: UserRole[];
	ui_permissions: UIPermission[];
}

export const usePermissionStore = defineStore('permission', {
	state: (): PermissionsState => ({
		roles: [],
		ui_permissions: []
	}),
	getters: {
		/**
		 * Determines if the passed in string is a valid role.
		 */
		isValidRole: (state) => (role: string): boolean  => state.roles.includes(role.toUpperCase())
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
				admin_required: p.admin_required ? true : false
			}));
		}
	}
});

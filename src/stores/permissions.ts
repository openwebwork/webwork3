// Permission store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';

export type UserRole = string;

interface UIPermission {
	route: string;
	allowed_roles: UserRole[];
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
		}
	}
});

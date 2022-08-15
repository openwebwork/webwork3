// Permission store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';
import { useSessionStore } from './session';
import { RouteLocationNormalized } from 'vue-router';
import { parseRouteCourseID, parseRouteUserID } from 'src/router/utils';
import { logger } from 'src/boot/logger';

export type UserRole = string;

interface UIPermission {
	route: string;
	allowed_roles: UserRole[];
	admin_required: boolean;
	allow_self_access: boolean;
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
		isValidRole: (state) => (role: string): boolean  => state.roles.includes(role),

		/**
		 * Determines if the current user (from the session store) has permission for the given route.
		 */
		hasRoutePermission: (state) => (route: RouteLocationNormalized): boolean => {
			// Find the longest matched route
			const permission = state.ui_permissions.reduce((prev, curr) => {
				const re = new RegExp(curr.route.replace('*', '.*?'));
				return (re.test(route.path) && curr.route.length > prev.route.length) ? curr : prev;
			}, { route: '', allowed_roles: [], admin_required: false, allow_self_access: false });

			if (permission.route === '') {
				logger.error(`[permission_store] Could not find a matching route for ${route.path}`);
				return true;
			}

			// free-for-all routes
			if (permission.allowed_roles[0] === '*') return true;

			// admin-only routes
			const session_store = useSessionStore();
			const user = session_store.user;
			if (permission.admin_required) return user.is_admin ?? false;

			// routes that 'belong' to a user
			const route_user_id = parseRouteUserID(route);
			if (permission.allow_self_access && route_user_id && route_user_id === user.user_id) return true;

			// all other permissioned routes
			const route_course_id = parseRouteCourseID(route);
			const user_course = session_store.user_courses.find((course) => course.course_id === route_course_id);
			const course_role = user_course?.role ?? 'unknown';
			return permission.allowed_roles.includes(course_role);
		}
	},
	actions: {
		async fetchRoles(): Promise<void> {
			const response = await api.get('roles/');
			this.roles = (response.data as string[]).map(role => role);
		},
		async fetchRoutePermissions(): Promise<void> {
			const response = await api.get('ui-permissions/');
			const perms = response.data as UIPermission[];

			this.ui_permissions = perms.map(p => ({
				allowed_roles: p.allowed_roles,
				route: p.route,
				admin_required: p.admin_required ?? false,
				allow_self_access: p.allow_self_access ?? false
			}));
		}
	}
});

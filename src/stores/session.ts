// Session store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';
import { SessionUser, User, default_session_user } from 'src/common/models/users';
import { ParseableSessionInfo, parseSessionInfo, SessionInfo, UserPassword } from 'src/common/models/session';
import { ParseableUserCourse } from 'src/common/models/courses';
import { logger } from 'boot/logger';
import { ResponseError } from 'src/common/api-requests/errors';

import { useUserStore } from 'src/stores/users';
import { useSettingsStore } from 'src/stores/settings';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { usePermissionStore, UserRole } from 'src/stores/permissions';

interface CourseInfo {
	course_name: string;
	role?: UserRole;
	course_id: number;
}

// SessionState should contain a de facto User, already parsed.
// In order for the session to be persistent, we need to store the fields username,
// user_id, etc.  instead of _username, _user_id from a Model.
export interface SessionState {
	logged_in: boolean;
	expiry: number;
	user: SessionUser;
	course: CourseInfo;
	user_courses: ParseableUserCourse[];
}

export const useSessionStore = defineStore('session', {
	// Stores this in localStorage.
	persist: true,
	state: (): SessionState => ({
		logged_in: false,
		expiry: 0,
		user: default_session_user,
		course: {
			course_id: 0,
			role: '',
			course_name: ''
		},
		user_courses: []
	}),
	getters: {
		full_name: (state): string => `${state.user.first_name ?? ''} ${state.user.last_name ?? ''}`,
		getUser: (state): User => new User(state.user),
	},
	actions: {
		updateExpiry(expiry: number): void {
			this.expiry = expiry;
		},
		// because this result may change despite state being unchanged, it is an action and not a getter
		authIsCurrent(): boolean {
			if (this.logged_in && this.expiry > Date.now()) return true;
			if (this.logged_in) this.logout();
			return false;
		},
		updateSessionInfo(session_info: SessionInfo): void {
			this.logged_in = session_info.logged_in;
			if (this.logged_in) {
				this.user = session_info.user;
			} else {
				this.user = default_session_user;
			}
		},
		setCourse(course_id: number): void {
			if (course_id === this.course.course_id) return;
			const new_course = this.user_courses.find((c) => c.course_id === course_id);
			if (!new_course) {
				logger.error(`[session_store] Attempted to select course #${course_id} -- not found!`);
				this.course = {
					course_id: 0,
					course_name: '',
					role: 'unknown'
				};
				return;
			}
			// in order to be reactive, replace the entire `this.course` object
			this.course = {
				course_id,
				course_name: new_course.course_name,
				role: new_course.role
			};
		},
		/**
		 * fetch all User Courses for a given user.
		 * @param {number} user_id
		 */
		async fetchUserCourses(): Promise<void> {
			if (!this.user.user_id) throw {
				message: 'No user has been authenticated',
			} as ResponseError;

			const response = await api.get(`users/${this.user.user_id}/courses`);
			if (response.status === 200) {
				this.user_courses = response.data as ParseableUserCourse[];
			} else {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		/**
		 * Attempt to login to webwork3 with username/password. If successful, fetch
		 * needed data (usercourses, roles, permissions).
		 */
		async login(user_pass: UserPassword): Promise<boolean> {
			const response = await api.post('login', user_pass);
			const session_info = parseSessionInfo(response.data as ParseableSessionInfo);
			if (!session_info.logged_in || !session_info.user.user_id) {
				return false;
			} else {
				// success
				this.updateSessionInfo(session_info);
				const permission_store = usePermissionStore();
				// permissions require access to user courses and respective roles
				await this.fetchUserCourses();
				await permission_store.fetchRoles();
				await permission_store.fetchRoutePermissions();
				return true;
			}
		},
		logout() {
			this.logged_in = false;
			this.user = default_session_user;
			this.course =  { course_id: 0, role: '', course_name: '' };
			useProblemSetStore().clearAll();
			useSettingsStore().clearAll();
			useUserStore().clearAll();
		}
	}
});

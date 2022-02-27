// Session store

import { defineStore } from 'pinia';
import { ParseableUser } from 'src/common/models/users';
import type { SessionInfo } from 'src/common/models/session';

interface CourseInfo {
	course_name: string;
	course_id: number;
}

export interface SessionState {
	logged_in: boolean;
	user: ParseableUser;
	course: CourseInfo;
}

export const useSessionStore = defineStore('session', {
	// Stores this in localStorage.
	persist: true,
	state: (): SessionState => ({
		logged_in: false,
		user: {},
		course: {
			course_id: 0,
			course_name: ''
		}
	}),
	getters: {
		full_name: (state): string => `${state.user?.first_name ?? ''} ${state.user?.last_name ?? ''} `
	},
	actions: {
		updateSessionInfo(session_info: SessionInfo): void {
			this.logged_in = session_info.logged_in;
			if (this.logged_in) {
				this.user = session_info.user;
				// state.user.is_admin = _session_info.user.is_admin;
			} else {
				this.user = {};
			}
		},
		setCourse(course: CourseInfo): void {
			this.course = course;
		},
		logout() {
			this.logged_in = false;
			this.user = {};
			this.course =  { course_id: 0, course_name: '' };
		}
	}
});

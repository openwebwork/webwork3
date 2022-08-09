// Session store

import { defineStore } from 'pinia';
import { api } from 'boot/axios';
import { User } from 'src/common/models/users';
import type { SessionInfo } from 'src/common/models/session';
import { ParseableUserCourse, UserCourse } from 'src/common/models/courses';
import { logger } from 'boot/logger';
import { ResponseError } from 'src/common/api-requests/errors';

import { useUserStore } from 'src/stores/users';
import { useSettingsStore } from 'src/stores/settings';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { UserRole } from 'src/stores/permissions';

interface CourseInfo {
	course_name: string;
	role?: UserRole;
	course_id: number;
}

// SessionState should contain a de facto User, already parsed
export interface SessionState {
	logged_in: boolean;
	expiry: number;
	user: User;
	course: CourseInfo;
	user_courses: UserCourse[];
}

export const useSessionStore = defineStore('session', {
	// Stores this in localStorage.
	persist: true,
	state: (): SessionState => ({
		logged_in: false,
		expiry: 0,
		user: new User({ username: 'logged_out' }),
		course: {
			course_id: 0,
			role: '',
			course_name: ''
		},
		user_courses: []
	}),
	getters: {
		full_name: (state): string => `${state.user?.first_name ?? ''} ${state.user?.last_name ?? ''}`,
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
				this.user = new User({ username: 'logged_out' });
			}
		},
		setCourse(course: CourseInfo): void {
			this.course = course;
			this.course.role = this.user_courses.find((c) => c.course_id === course.course_id)?.role || '';
		},
		/**
		 * fetch all User Courses for a given user.
		 * @param {number} user_id
		 */
		async fetchUserCourses(user_id: number): Promise<void> {
			const response = await api.get(`users/${user_id}/courses`);
			if (response.status === 200) {
				this.user_courses = (response.data as ParseableUserCourse[])
					.map(user_course => new UserCourse({
						course_id: user_course.course_id,
						user_id: user_course.user_id,
						visible: user_course.visible,
						role: user_course.role,
						course_name: user_course.course_name,
					}));
			} else {
				logger.error(response.data);
				throw response.data as ResponseError;
			}
		},
		logout() {
			this.logged_in = false;
			this.user = new User({ username: 'logged_out' });
			this.course =  { course_id: 0, role: '', course_name: '' };
			useProblemSetStore().clearAll();
			useSettingsStore().clearAll();
			useUserStore().clearAll();
		}
	}
});

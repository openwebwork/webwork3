/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// session.spec.ts
// Test the Session Store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { SessionInfo } from 'src/common/models/session';
import { User } from 'src/common/models/users';
import { useSessionStore } from 'src/stores/session';

const app = createApp({});

describe('Session Store', () => {
	beforeAll(() => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);
	});

	describe('Testing the Session', () => {
		const user: User = new User({
			first_name: 'Homer',
			last_name: 'Simpson',
			user_id: 1234,
			email: 'homer@msn.com',
			username: 'homer',
			is_admin: false
		});

		const logged_out: User = new User({
			username: 'logged_out'
		});

		const session_info: SessionInfo = {
			logged_in: true,
			user,
			message: 'hi there'
		};

		test('default session', () => {
			const session = useSessionStore();

			expect(session.logged_in).toBe(false);
			expect(session.user).toStrictEqual(logged_out);
			expect(session.course).toStrictEqual({
				course_id: 0,
				course_name: ''
			});
		});

		test('update the session', () => {
			const session = useSessionStore();

			session.updateSessionInfo(session_info);

			expect(session.logged_in).toBe(true);
			expect(session.user).toStrictEqual(user);

			const course = {
				course_name: 'Arithmetic',
				course_id: 1
			};

			session.setCourse(course);

			expect(session.course).toStrictEqual(course);

		});

		test('logging out should clear the session', () => {
			const session = useSessionStore();
			// Update the session info as if being logged in.
			session.updateSessionInfo(session_info);

			session.logout();

			expect(session.logged_in).toBe(false);
			expect(session.user).toStrictEqual(logged_out);

		});
	});

});

// session.spec.ts
// Test the Session Store

import { setActivePinia, createPinia } from 'pinia';
import { SessionInfo } from 'src/common/models/session';
import { ParseableUser } from 'src/common/models/users';
import { useSessionStore } from 'src/stores/session';

// Some common objects.

const user: ParseableUser = {
	first_name: 'Homer',
	last_name: 'Simpson',
	user_id: 1234,
	email: 'homer@msn.com',
	username: 'homer',
	is_admin: false
};

const session_info: SessionInfo = {
	logged_in: true,
	user,
	message: 'hi there'
};

describe('Session Store', () => {
	beforeEach(() => {
		// creates a fresh pinia and make it active so it's automatically picked
		// up by any useStore() call without having to pass it to it:
		// `useStore(pinia)`
		setActivePinia(createPinia());
	});

	test('default session', () => {
		const session = useSessionStore();

		expect(session.logged_in).toBe(false);
		expect(session.user).toStrictEqual({});
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
		expect(session.user).toStrictEqual({});

	});

});

/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// session.spec.ts
// Test the Session Store

import { setActivePinia, createPinia } from 'pinia';
import { getUser } from 'src/common/api-requests/user';
import { Course, UserCourse } from 'src/common/models/courses';
import { SessionInfo } from 'src/common/models/session';
import { CourseUser, User } from 'src/common/models/users';
import { useSessionStore } from 'src/stores/session';
import { useUserStore } from 'src/stores/users';
import { cleanIDs, loadCSV } from '../utils';

// Some common objects.

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

describe('Session Store', () => {
	let lisa_courses: UserCourse[];
	let lisa: User;
	beforeAll(async () => {
		// creates a fresh pinia and make it active so it's automatically picked
		// up by any useStore() call without having to pass it to it:
		// `useStore(pinia)`
		setActivePinia(createPinia());

		// Load the user course information for testing later.

		const parsed_courses = await loadCSV('t/db/sample_data/courses.csv', {
			boolean_fields: ['visible'],
			non_neg_fields: ['course_id'],
			params: ['course_dates', 'course_params']
		});

		const courses_from_csv = parsed_courses.map(course => {
			delete course.course_params;
			return new Course(course);
		});

		const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
			boolean_fields: ['is_admin'],
			non_neg_fields: ['user_id']
		});
		const all_users_from_csv = users_to_parse.map(user => new User(user));
		lisa_courses = users_to_parse.filter(user => user.username === 'lisa')
			.map(user_course => {
				const course = courses_from_csv.find(c => c.course_name == user_course.course_name)
					?? new Course();
				return new UserCourse({
					course_name: course.course_name,
					username: user_course.username as string,
					visible: course.visible,
					role: user_course.role as string,
					course_dates: course.course_dates
				});
			});

		// Fetch the user lisa.  This is used below.
		lisa = new User(await getUser('lisa'));
	});

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

	test('check user courses', async () => {
		const session_store = useSessionStore();
		await session_store.fetchUserCourses(lisa.user_id);
		expect(cleanIDs(session_store.user_courses)).toStrictEqual(cleanIDs(lisa_courses));
	})

});

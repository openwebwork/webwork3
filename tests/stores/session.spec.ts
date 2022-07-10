/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// session.spec.ts
// Test the Session Store

import { createApp } from 'vue';
import { setActivePinia, createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { getUser } from 'src/common/api-requests/user';
import { useSessionStore } from 'src/stores/session';
import { checkPassword } from 'src/common/api-requests/session';

import { Course, UserCourse } from 'src/common/models/courses';
import { SessionInfo } from 'src/common/models/session';
import { User } from 'src/common/models/users';

import { cleanIDs, loadCSV } from '../utils';

const app = createApp({});

describe('Session Store', () => {
	let lisa_courses: UserCourse[];
	let lisa: User;

	const user: User = new User({
		first_name: 'Homer',
		last_name: 'Simpson',
		user_id: 1234,
		email: 'homer@msn.com',
		username: 'homer',
		is_admin: false,
	});

	const logged_out: User = new User({
		username: 'logged_out'
	});

	const session_info: SessionInfo = {
		logged_in: true,
		user,
		message: 'hi there'
	};

	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as the admin in order to be authenticated for the rest of the test.
		await api.post('login', { username: 'admin', password: 'admin' });

		// Load the user course information for testing later.
		const parsed_courses = await loadCSV('t/db/sample_data/courses.csv', {
			boolean_fields: ['visible'],
			non_neg_int_fields: ['course_id'],
			params: ['course_dates', 'course_params']
		});

		const courses_from_csv = parsed_courses.map(course => {
			delete course.course_params;
			return new Course(course);
		});

		const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
			boolean_fields: ['is_admin'],
			non_neg_int_fields: ['user_id']
		});

		// Fetch the user lisa.  This is used below.
		lisa = new User(await getUser('lisa'));

		lisa_courses = users_to_parse.filter(user => user.username === 'lisa')
			.map(user_course => {
				const course = courses_from_csv.find(c => c.course_name == user_course.course_name)
							?? new Course();
				return new UserCourse({
					course_name: course.course_name,
					user_id: lisa.user_id,
					visible: course.visible,
					role: user_course.role as string,
					course_dates: course.course_dates
				});
			});

	});

	describe('Testing the Session Store.', () => {
		test('default session', () => {
			const session = useSessionStore();

			expect(session.logged_in).toBe(false);
			expect(session.user).toStrictEqual(logged_out);
			expect(session.course).toStrictEqual({
				course_id: 0,
				course_name: '',
				role: ''
			});
		});

		test('Login as a user', async () => {
		// test logging in as lisa gives the proper courses.
			const session_info = await checkPassword({
				username: 'lisa', password: 'lisa'
			});
			expect(session_info.logged_in).toBe(true);
			expect(session_info.user).toStrictEqual(lisa.toObject());

		});

		test('check user courses', async () => {
			const session_store = useSessionStore();
			await session_store.fetchUserCourses(lisa.user_id);
			expect(cleanIDs(session_store.user_courses)).toStrictEqual(cleanIDs(lisa_courses));
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

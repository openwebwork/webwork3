/** @jest-environment jsdom */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

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
import { ParseableUser, User } from 'src/common/models/users';

import { cleanIDs } from '../utils';

const app = createApp({});

describe('Session Store', () => {
	const lisa_courses: UserCourse[] = [];
	let lisa: User;

	// session now just stores objects not models:
	const user: ParseableUser = {
		first_name: 'Homer',
		last_name: 'Simpson',
		user_id: 1234,
		email: 'homer@msn.com',
		username: 'homer',
		is_admin: false,
	};

	const logged_out: ParseableUser = {
		username: 'logged_out',
		email: '',
		last_name: '',
		first_name: '',
		user_id: 0,
		is_admin: false,
		student_id: ''
	};

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
		const courses_from_json = (await import('../../t/db/sample_data/courses.json')).default.map(
			(course) => new Course(course)
		);

		const users_to_parse = (await import('../../t/db/sample_data/users.json')).default;

		// Fetch the user lisa.  This is used below.
		lisa = new User(await getUser('lisa'));

		users_to_parse
			.find((user) => user.username === 'lisa')
			?.courses?.forEach((course_info) => {
				const course = courses_from_json.find((c) => c.course_name == course_info.course_name) ?? new Course();
				lisa_courses.push(
					new UserCourse({
						course_id: 0,
						course_name: course.course_name,
						user_id: lisa.user_id,
						visible: course.visible,
						role: course_info.course_user.role,
						course_dates: course.course_dates,
					})
				);
			});
	});

	describe('Testing the Session Store.', () => {
		test('default session', () => {
			const session = useSessionStore();

			expect(session.logged_in).toBe(false);
			expect(session.user.username).toBe('logged_out');
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

			const session = useSessionStore();
			session.updateSessionInfo(session_info);

			expect(session.logged_in).toBe(true);
			expect(session.user).toStrictEqual(lisa.toObject());

		});

		// sort by course name and clean up the _id tags.
		const sortAndClean = (user_courses: UserCourse[]) => {
			return cleanIDs(user_courses.sort((a, b) =>
				a.course_name < b.course_name ? -1 : a.course_name > b.course_name ? 1 : 0));
		};

		test('check user courses', async () => {
			const session_store = useSessionStore();
			await session_store.fetchUserCourses();
			expect(sortAndClean(session_store.user_courses.map(c => new UserCourse(c))))
				.toStrictEqual(sortAndClean(lisa_courses));
		});

		test('update the session', () => {
			const session = useSessionStore();
			const user_course = session.user_courses.find((c) => c.course_name === 'Arithmetic');
			expect(user_course?.course_id).toBeTruthy();
			const course = {
				course_name: user_course?.course_name,
				course_id: user_course?.course_id,
				role: user_course?.role
			};

			session.setCourse(user_course?.course_id ?? 0);
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

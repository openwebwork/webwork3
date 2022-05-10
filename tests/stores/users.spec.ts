/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// problem_sets.spec.ts
// Test the problem sets Store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import { cleanIDs, loadCSV } from '../utils';
import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import { CourseUser, User } from 'src/common/models/users';
import { useUserStore } from 'src/stores/users';

const app = createApp({});

describe('User store tests', () => {
	let global_users: User[];
	let precalc_global_users: User[];
	let precalc_users: CourseUser[];
	let precalc_course: Course;
	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
			boolean_fields: ['is_admin'],
			non_neg_fields: ['user_id']
		});

		// Do some parsing and cleanup.
		const all_users_from_csv = users_to_parse.map(user => new User(user));
		precalc_global_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
			.map(user => new User(user));
		precalc_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
			.map(user => new CourseUser(user));

		// remove duplicates (for users in multiple courses) for global users
		const usernames = [... new Set(all_users_from_csv.map(user => user.username))];
		global_users = usernames.map(username => all_users_from_csv
			.find(user => user.username === username) ?? new User());

		// fetch the courses, so we can get the course_id of desired course.
		const course_store = useCourseStore();
		await course_store.fetchCourses();
		precalc_course = course_store.findCourse({ course_name: 'Precalculus' }) as Course;
	});

	describe('Fetch all global users', () => {
		test('Fetch all users', async () => {
			const user_store = useUserStore();
			await user_store.fetchUsers();
			// drop the admin user.
			const all_users = user_store.users.filter(user => user.username !== 'admin');
			expect(cleanIDs(all_users)).toStrictEqual(cleanIDs(global_users));
		});
	});

	describe('CRUD functions for global users', () => {
		let added_user: User;
		test('Add a new global user', async () => {
			const user_store = useUserStore();
			const new_user = new User({
				username: 'maggie',
				first_name: 'Maggie',
				last_name: 'Simpson',
				email: 'maggie@gmail.com'
			});
			added_user = await user_store.addUser(new_user) ?? new User();
			expect(cleanIDs(added_user)).toStrictEqual(cleanIDs(new_user));
		});

		test('Update a user', async () => {
			const user_store = useUserStore();
			added_user.email = 'maggie@msn.com';
			const updated_user = await user_store.updateUser(added_user) ?? new User();
			expect(cleanIDs(updated_user)).toStrictEqual(cleanIDs(added_user));
		});

		test('Delete a global user', async () => {
			const user_store = useUserStore();
			const deleted_user = await user_store.deleteUser(added_user) ?? new User();
			expect(cleanIDs(deleted_user)).toStrictEqual(cleanIDs(added_user));
		});
	});

	describe('Fetch course users', () => {
		test('Fetch all users of a course', async () => {
			const user_store = useUserStore();
			await user_store.fetchCourseUsers(precalc_course.course_id);
			expect(user_store.course_users.length).toBe(precalc_users.length);
		});
	});

	describe('CRUD functions on course users', () => {
		let user_not_in_precalc: User;
		test('Add a new course user', async () => {
			const user_store = useUserStore();
			// Find a global user that is not in the Precalculus course
			user_not_in_precalc = (user_store.users.filter(u => !u.is_admin)
				.find(user => precalc_global_users
					.findIndex(u => u.username === user.username) < 0) as User) ?? new User();
			const new_course_user = new CourseUser(user_not_in_precalc);
			new_course_user.set({
				course_id: precalc_course.course_id,
				role: 'STUDENT'
			});
			const added_course_user = await user_store.addCourseUser(new_course_user);
			new_course_user.course_user_id = added_course_user.course_user_id;
			expect(new_course_user).toStrictEqual(new_course_user);
		});

		test('Update a Course User', async () => {
			const user_store = useUserStore();
			const course_user_to_update = user_store.course_users
				.find(user => user.user_id === user_not_in_precalc.user_id)?.clone();
			if (course_user_to_update) {
				course_user_to_update.recitation = 3;
				const updated_user = await user_store.updateCourseUser(course_user_to_update);
				expect(updated_user).toStrictEqual(course_user_to_update);
			}

		});

		test('Delete Course User', async () => {
			const user_store = useUserStore();
			const user_to_delete = user_store.course_users.find(user => user.user_id === user_not_in_precalc.user_id);
			const deleted_user = await user_store.deleteCourseUser(user_to_delete as CourseUser);
			expect(user_to_delete).toStrictEqual(deleted_user);
		});
	});

	describe('Check global and course users', () => {

		test('Fetch global users for a course', async () => {
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			expect(cleanIDs(precalc_global_users)).toStrictEqual(cleanIDs(user_store.users));
		});

		test('Check course users users', () => {
			const user_store = useUserStore();
			expect(cleanIDs(user_store.course_users)).toStrictEqual(cleanIDs(precalc_users));
		});
	});
});

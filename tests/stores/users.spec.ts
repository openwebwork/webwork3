/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// users.spec.ts
// Test the users Store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { cleanIDs, loadCSV } from '../utils';
import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import { CourseUser, MergedUser, User } from 'src/common/models/users';
import { useUserStore } from 'src/stores/users';

const app = createApp({});

describe('User store tests', () => {
	let global_users: User[];
	let all_precalc_users: User[];
	let precalc_merged_users: MergedUser[];
	let precalc_course: Course;
	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as the admin in order to be authenticated for the rest of the test.
		await api.post('login', { username: 'admin', password: 'admin' });

		const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
			boolean_fields: ['is_admin'],
			non_neg_fields: ['user_id']
		});

		// Do some parsing and cleanup.
		const all_users_from_csv = users_to_parse.map(user => new User(user));
		all_precalc_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
			.map(user => new User(user));
		precalc_merged_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
			.map(user => new MergedUser(user));

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
			expect(user_store.course_users.length).toBe(all_precalc_users.length);
		});
	});

	describe('CRUD functions on course users', () => {
		let user_not_in_precalc: User;
		test('Add a new course user', async () => {
			const user_store = useUserStore();
			// Find a global user that is not in the Precalculus course
			user_not_in_precalc = (user_store.users.find(user => all_precalc_users
				.findIndex(u => u.username === user.username) < 0) as User) ?? new User();
			const new_course_user_params = {
				course_id: precalc_course.course_id,
				user_id: user_not_in_precalc?.user_id,
				role: 'STUDENT'
			};
			const new_course_user = await user_store.addCourseUser(new CourseUser(new_course_user_params));
			const new_course_user2 = new_course_user.toObject();
			delete new_course_user2.course_user_id;
			expect(new_course_user2).toStrictEqual(new_course_user_params);
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

	describe('Check merged users', () => {

		test('Fetch global users for a course', async () => {
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			expect(cleanIDs(all_precalc_users)).toStrictEqual(cleanIDs(user_store.users));
		});

		test('Check merged users', () => {
			const user_store = useUserStore();
			expect(cleanIDs(user_store.merged_users)).toStrictEqual(cleanIDs(precalc_merged_users));
		});
	});
});

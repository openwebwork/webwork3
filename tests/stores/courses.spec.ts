/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// courses.spec.ts
// Test the Course Store

import { setActivePinia, createPinia } from 'pinia';
import { useCourseStore } from 'src/stores/courses';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { Course } from 'src/common/models/courses';
import { cleanIDs, loadCSV } from '../utils';
import { useSessionStore } from 'src/stores/session';
import { api } from 'src/boot/axios';
describe('Test the course store', () => {

	const app = createApp({});

	describe('Set up the Course Store', () => {
		let courses_from_csv: Course[];
		beforeAll(async () => {
			// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
			const pinia = createPinia().use(piniaPluginPersistedstate);
			app.use(pinia);
			setActivePinia(pinia);

			const session_store = useSessionStore();
			const parsed_courses = await loadCSV('t/db/sample_data/courses.csv', {
				boolean_fields: ['visible'],
				non_neg_fields: ['course_id'],
				params: ['course_dates', 'course_params']
			});
			courses_from_csv = parsed_courses.map(course => {
				delete course.course_params;
				return new Course(course);
			});
			// Login to the course as the admin in order to be authenticated for the
			// rest of the test.
			await api.post('login', { username: 'admin', password: 'admin' });
		});

		test('Fetch the courses', async () => {
			const course_store = useCourseStore();
			await course_store.fetchCourses();
			expect(cleanIDs(course_store.courses)).toStrictEqual(cleanIDs(courses_from_csv));
		});
	});

	describe('CRUD operations on a course', () => {
		let added_course: Course;
		let updated_course: Course;
		test('Add a New Course', async () => {
			const course_store = useCourseStore();
			const new_course = new Course({
				course_name: 'My New Course',
				course_dates: {
					start: 60000000,
					end: 60000200
				},
				visible: true
			});
			added_course = await course_store.addCourse(new_course) ?? new Course();
			expect(cleanIDs(added_course)).toStrictEqual(cleanIDs(new_course));
		});

		test('Update a course', async () => {
			const course_store = useCourseStore();
			const course_to_update = added_course.clone();
			course_to_update.visible = false;
			updated_course = await course_store.updateCourse(course_to_update) ?? new Course();
			expect(cleanIDs(updated_course)).toStrictEqual(cleanIDs(course_to_update));
		});

		test('Delete a course', async () => {
			const course_store = useCourseStore();
			const deleted_course = await course_store.deleteCourse(added_course) ?? new Course();
			expect(cleanIDs(deleted_course)).toStrictEqual(cleanIDs(updated_course));
		});
	});
});

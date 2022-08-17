/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// courses.spec.ts
// Test the Course Store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import { cleanIDs, loadCSV } from '../utils';
import { AxiosError } from 'axios';

describe('Test the course store', () => {

	const app = createApp({});

	describe('Set up the Course Store', () => {
		let courses_from_csv: Course[];

		beforeAll(async () => {
			// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
			const pinia = createPinia().use(piniaPluginPersistedstate);
			app.use(pinia);
			setActivePinia(pinia);

			const parsed_courses = await loadCSV('t/db/sample_data/courses.csv', {
				boolean_fields: ['visible'],
				non_neg_int_fields: ['course_id'],
				params: ['course_dates', 'course_params']
			});
			courses_from_csv = parsed_courses.map(course => {
				delete course.course_params;
				return new Course(course);
			});

			// Login to the course as the admin in order to be authenticated for the rest of the test.
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
			await course_store.deleteCourse(added_course);

			// Check that the course is no longer in the database by getting an exception.
			await api.get(`/courses/${added_course.course_id}`)
				.then(() => {
					fail('Expected failure response');
				})
				.catch((e: AxiosError) => {
					expect(e.response?.status).toBe(500);
					expect((e.response?.data as {exception: string}).exception)
						.toBe('DB::Exception::CourseNotFound');
				});
		});
	});

	describe('Test that invalid courses are handled correctly', () => {
		test('Try to add an invalid course', async () => {
			const course_store = useCourseStore();

			// This course is invalid because the name is the empty string.
			const course = new Course({
				course_name: ''
			});
			expect(course.isValid()).toBe(false);
			await expect(async () => {
				await course_store.addCourse(course);
			}).rejects.toThrow('The added course is invalid');
		});

		test('Try to update an invalid course', async () => {
			const course_store = useCourseStore();
			const precalc = course_store.courses.find(c => c.course_name === 'Precalculus');
			if (precalc) {
				precalc.course_dates.start = 200;
				precalc.course_dates.end = 100;
				expect(precalc.isValid()).toBe(false);
				await expect(async () => { await course_store.updateCourse(precalc as Course); })
					.rejects.toThrow('The updated course is invalid');
			} else {
				throw 'This should not have be thrown.  Course precalc is not defined.';
			}
		});
	});
});

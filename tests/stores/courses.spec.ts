/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// courses.spec.ts
// Test the Course Store

import { setActivePinia, createPinia } from 'pinia';
import { useCourseStore } from 'src/stores/courses';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { parseBoolean } from 'src/common/models/parsers';
import { Dictionary } from 'src/common/models';
import { Course, ParseableCourse } from 'src/common/models/courses';
import { cleanIDs, loadCSV } from '../utils';
import { text } from 'body-parser';
import { add } from 'winston';

describe('Test the course store', () => {

	const app = createApp({});

	const convertCourses = (data: Dictionary<string>[]): ParseableCourse[] => {
		return data.map(row => ({
			course_name: row.course_name,
			visible: parseBoolean(row.visible),
			course_dates: Object.entries(row)
				.reduce((prev: Dictionary<string | number>, [key, value]) => {
					const parse_dates = /DATES:(\w+)?$/.exec(key);
					if (parse_dates) {
						prev[parse_dates[1]] = value;
					}
					return prev;
				}, {})
		}));
	};

	describe('Set up the Course Store', () => {
		let courses_from_csv: Course[];
		beforeEach(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
			const pinia = createPinia().use(piniaPluginPersistedstate);
			app.use(pinia);
			setActivePinia(pinia);

			const parsed_courses = await loadCSV('t/db/sample_data/courses.csv', {
				boolean_fields: ['visible'],
				non_neg_fields: ['course_id'],
				params: ['course_dates', 'course_params']
			});
			courses_from_csv = parsed_courses.map(course => {
				delete course.course_params;
				return new Course(course);
			});
		});

		test('Fetch the courses', async () => {
			const course_store = useCourseStore();
			await course_store.fetchCourses();
			const all_courses = course_store.courses.map(course => ({
				course_name: course.course_name,
				visible: course.visible,
				course_dates: { ...course.course_dates }
			}));

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

		test('Update a course',async () => {
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

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
import papa from 'papaparse';
import fs from 'fs';
import { CourseSetting } from 'src/common/models/settings';
import { parseBoolean } from 'src/common/models/parsers';
import { Dictionary } from 'src/common/models';
import { Course, ParseableCourse } from 'src/common/models/courses';

const app = createApp({});


const convertCourses = (data: Dictionary<string>[]): ParseableCourse[] => {
	return data.map(row => ({
		course_name: row.course_name,
		visible: parseBoolean(row.visible),
		course_dates: Object.entries(row)
			.reduce((prev: Dictionary<string|number>, [key, value]) => {
				const parse_dates = /DATES:(\w+)?$/.exec(key);
				if (parse_dates) {
					prev[parse_dates[1]] = value;
				}
				return prev;
			},{})
	}));
};

describe('Set up the Course Store', () => {
	let courses_from_csv: ParseableCourse[];
	beforeEach(() => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// read the courses.csv file
		papa.parse(fs.createReadStream('t/db/sample_data/courses.csv'), {
			header: true,
			complete: function(results) {
				courses_from_csv = convertCourses(results.data as { [key: string]: string }[]);
			}
		});
	});

	test('Fetch the courses', async () => {
		const course_store = useCourseStore();
		await course_store.fetchCourses();
		const all_courses = course_store.courses.map(course => ({
			course_name: course.course_name,
			visible: course.visible,
			course_dates: {...course.course_dates}
		}));

		expect(all_courses).toStrictEqual(courses_from_csv);
	});
});

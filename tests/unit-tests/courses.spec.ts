// tests parsing and handling of users

import { Course, ParseableCourse } from 'src/common/models/courses';
import { NonNegIntException } from 'src/common/models/parsers';
import { InvalidFieldsException } from 'src/common/models';

describe('Test Course Models', () => {

	const default_course = {
		course_id: 0,
		course_name: 'Arithmetic',
		visible: true,
		course_dates: { start: 0, end: 0 }
	};

	describe('Creation of a Course', () => {

		test('Create a Valid Course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			expect(course).toBeInstanceOf(Course);

			expect(course.toObject()).toStrictEqual(default_course);

			expect(course.isValid()).toBe(true);

		});

		test('Check that calling all_fields() and params() is correct', () => {
			const course_fields = ['course_id', 'course_name', 'visible', 'course_dates'];
			const course = new Course({ course_name: 'Arithmetic' });

			expect(course.all_field_names.sort()).toStrictEqual(course_fields.sort());
			expect(course.param_fields.sort()).toStrictEqual(['course_dates']);

			expect(Course.ALL_FIELDS.sort()).toStrictEqual(course_fields.sort());

		});

		test('Check that cloning works', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			expect(course.clone().toObject()).toStrictEqual(default_course);
			expect(course.clone()).toBeInstanceOf(Course);
		});

	});

	describe('Updating a course', () => {
		test('set fields of a course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.course_id = 5;
			expect(course.course_id).toBe(5);

			course.course_name = 'Geometry';
			expect(course.course_name).toBe('Geometry');

			course.visible = false;
			expect(course.visible).toBe(false);
			expect(course.isValid()).toBe(true);

		});

		test('set fields of a course using the set method', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.set({
				course_id: 5,
				course_name: 'Geometry',
				visible: false
			});
			expect(course.course_id).toBe(5);
			expect(course.course_name).toBe('Geometry');
			expect(course.visible).toBe(false);
			expect(course.isValid()).toBe(true);
		});
	});

	describe('Checking the course dates', () => {
		test('checking for valid course dates', () => {
			const course = new Course({
				course_name: 'Arithemetic',
				course_dates: {start: 100, end: 100}
			});
			expect(course.course_dates.isValid()).toBe(true);
			expect(course.isValid()).toBe(true);
		});
	});

	describe('Checking valid and invalid creation parameters.', () => {

		test('Parsing of undefined and null values', () => {
			const course1 = new Course({ course_name: 'Arithmetic' });
			const course2 = new Course({ course_name: 'Arithmetic', course_id: undefined });
			expect(course1).toStrictEqual(course2);

			// the following allow to pass in non-valid parameters for testing
			const params = { course_name: 'Arithmetic', course_id: null };
			const course3 = new Course(params as unknown as ParseableCourse);
			expect(course1).toStrictEqual(course3);
		});

		test('Create a course with invalid fields', () => {
			const c1 = new Course({ course_name: 'Arithmetic', course_id: -1 });
			expect(c1.isValid()).toBe(false);

			const c2 = new Course({ course_name: '', course_id: 0 });
			expect(c2.isValid()).toBe(false);
		});

		test('Create a course with invalid dates', () => {
			const c1 = new Course({
				course_name: 'Arithmetic',
				course_dates: { start: 100, end: 0}
			});
			expect(c1.isValid()).toBe(false);

		});
	});


});

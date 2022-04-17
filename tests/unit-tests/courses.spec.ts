// tests parsing and handling of users

import { Course, ParseableCourse } from 'src/common/models/courses';
import { NonNegIntException } from 'src/common/models/parsers';
import { InvalidFieldsException } from 'src/common/models';

describe('Test Course Models', () => {

	const default_course_dates = { start: 0, end: 0 };

	const default_course = {
		course_id: 0,
		course_name: 'Arithmetic',
		visible: true,
		course_dates: { ...default_course_dates }
	};

	describe('Creation of a Course', () => {

		test('Create a Valid Course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			expect(course).toBeInstanceOf(Course);

			expect(course.toObject()).toStrictEqual(default_course);

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

		test('Create a course with invalid params', () => {
			// make a generic object and cast it as a Course
			const p = { course_name: 'Arithmetic', CourseNumber: -1 } as unknown as ParseableCourse;
			expect(() => { new Course(p);})
				.toThrow(InvalidFieldsException);
		});

		test('Course with invalid course_id', () => {
			expect(() => {
				new Course({ course_name: 'Arithmetic', course_id: -1 });
			}).toThrow(NonNegIntException);
		});
	});

	describe('Updating a course', () => {

		test('set fields of a course', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.course_id = 5;
			expect(course.course_id).toBe(5);

			course.course_name = 'Geometry';
			expect(course.course_name).toBe('Geometry');

			course.visible = true;
			expect(course.visible).toBeTruthy();

			course.visible = 0;
			expect(course.visible).toBeFalsy();

			course.visible = 'true';
			expect(course.visible).toBeTruthy();

			course.visible = 'false';
			expect(course.visible).toBeFalsy();

		});

		test('set fields of a course using the set method', () => {
			const course = new Course({ course_name: 'Arithmetic' });
			course.set({ course_id: 5 });
			expect(course.course_id).toBe(5);

			course.set({ course_name: 'Geometry' });
			expect(course.course_name).toBe('Geometry');

			course.set({ visible: true });
			expect(course.visible).toBeTruthy();

			course.set({ visible: 'true' });
			expect(course.visible).toBeTruthy();

			course.set({ visible: 'false' });
			expect(course.visible).toBeFalsy();

			course.set({ visible: 0 });
			expect(course.visible).toBeFalsy();
		});
	});
});

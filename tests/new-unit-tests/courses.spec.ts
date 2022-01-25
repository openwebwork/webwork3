// tests parsing and handling of users

import { Course, ParseableCourse } from 'src/common/models/courses';
import { NonNegIntException } from 'src/common/models/parsers';
import { InvalidFieldsException } from 'src/common/models';

test('Create a Valid Course', () => {
	const course = new Course({ course_name: 'Arithmetic' });
	expect(course instanceof Course).toBe(true);

	const course1 = new Course({ course_name: 'Arithmetic' });
	const course2 = new Course({ course_name: 'Arithmetic', course_id: 0 });
	course2.setDates({ start: '', end: '' });
	expect(course1.toObject()).toStrictEqual(course2.toObject());

});

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

test('set fields of a course', () => {
	const course = new Course({ course_name: 'Arithmetic' });
	course.course_id = 5;
	expect(course.course_id).toBe(5);

	course.course_name = 'Geometry';
	expect(course.course_name).toBe('Geometry');

	course.visible = true;
	expect(course.visible).toBe(true);

	course.visible = 0;
	expect(course.visible).toBe(false);

	course.visible = 'true';
	expect(course.visible).toBe(true);

	course.visible = 'false';
	expect(course.visible).toBe(false);

});

test('set fields of a course using the set method', () => {
	const course = new Course({ course_name: 'Arithmetic' });
	course.set({ course_id: 5 });
	expect(course.course_id).toBe(5);

	course.set({ course_name: 'Geometry' });
	expect(course.course_name).toBe('Geometry');

	course.set({ visible: true });
	expect(course.visible).toBe(true);

	course.set({ visible: 'true' });
	expect(course.visible).toBe(true);

	course.set({ visible: 'false' });
	expect(course.visible).toBe(false);

	course.set({ visible: 0 });
	expect(course.visible).toBe(false);
});

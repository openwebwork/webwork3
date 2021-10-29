// tests parsing and handling of users

import { Course, ParseableCourse } from '@/store/models/courses';
import { NonNegIntException, InvalidFieldsException } from '@/store/models';

test('Create a Valid Course', () => {
	const course = new Course();
	expect(course instanceof Course).toBe(true);

	const course1 = new Course({ course_name: 'Arithmetic' });
	const course2 = new Course({ course_name: 'Arithmetic', course_id: 0 });
	course2.setDates({ start: '', end: '' });
	expect(course1).toStrictEqual(course2);

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
	const p = { CourseName: 'Arithmetic' };
	expect(() => { new Course(p as ParseableCourse);})
		.toThrow(InvalidFieldsException);
});

test('Course with invalid course_id', () => {
	expect(() => {
		new Course({ course_id: -1 });
	}).toThrow(NonNegIntException);
});

test('set fields of a course', () => {
	const course = new Course();
	course.set({ course_id: 5 });
	expect(course.course_id).toBe(5);

	course.set({ course_name: 'Geometry' });
	expect(course.course_name).toBe('Geometry');

	course.set({ visible: true });
	expect(course.visible).toBe(true);

	course.set({ visible: 0 });
	// console.log(course);
	expect(course.visible).toBe(false);

	course.set({ visible: 'true' });
	expect(course.visible).toBe(true);

	course.set({ visible: 'false' });
	expect(course.visible).toBe(false);

});

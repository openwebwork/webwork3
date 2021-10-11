// tests parsing and handling of users

import { Course } from '@/store/models/courses';
import { NonNegIntException } from '@/store/models';

test('Create a Valid CourseUser', () => {
	const course = new Course();
	expect(course instanceof Course).toBe(true);

	const course1 = new Course({ course_name: 'Arithmetic' });
	const course2 = new Course({ course_name: 'Arithmetic', course_id: 0,
		course_dates: { start: '', end: '' } });
	expect(course1).toStrictEqual(course2);

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

// tests parsing and handling of users

import { CourseUser } from 'src/common/models/users';
import { NonNegIntException, UserRoleException } from 'src/common/models/parsers';

test('Create a Valid CourseUser', () => {
	const course_user = new CourseUser();
	expect(course_user instanceof CourseUser).toBe(true);
});

test('CourseUser with invalid role', () => {
	expect(() => {
		new CourseUser({ role: 'superhero' });
	}).toThrow(UserRoleException);
});

test('set fields of CourseUser', () => {
	const course_user = new CourseUser();

	course_user.role = 'student';
	expect(course_user.role).toBe('student');

	course_user.course_id = 34;
	expect(course_user.course_id).toBe(34);

	course_user.user_id = 3;
	expect(course_user.user_id).toBe(3);

	course_user.user_id = '5';
	expect(course_user.user_id).toBe(5);

	course_user.section = 2;
	expect(course_user.section).toBe('2');

	course_user.section = '12';
	expect(course_user.section).toBe('12');

});

test('set fields of CourseUser using set()', () => {
	const course_user = new CourseUser();
	course_user.set({ role: 'student' });
	expect(course_user.role).toBe('student');

	course_user.set({ course_id: 34 });
	expect(course_user.course_id).toBe(34);

	course_user.set({ user_id: 3 });
	expect(course_user.user_id).toBe(3);

	course_user.set({ user_id: '5' });
	expect(course_user.user_id).toBe(5);

	course_user.set({ section: 2 });
	expect(course_user.section).toBe('2');

	course_user.set({ section: '12' });
	expect(course_user.section).toBe('12');

});

test('set invalid role', () => {
	const course_user = new CourseUser({ role: 'student' });
	expect(() => { course_user.role = 'superhero';}).toThrow(UserRoleException);
});

test('set invalid user_id', () => {
	const course_user = new CourseUser();
	expect(() => { course_user.user_id = -1; }).toThrow(NonNegIntException);
	expect(() => { course_user.user_id = '-1'; }).toThrow(NonNegIntException);
});

test('set invalid course_id', () => {
	const course_user = new CourseUser();
	expect(() => { course_user.course_id = -1;}).toThrow(NonNegIntException);
	expect(() => { course_user.course_id = '-1'; }).toThrow(NonNegIntException);
});

test('set invalid course_user_id', () => {
	const course_user = new CourseUser();
	expect(() => { course_user.course_user_id =  -1; }).toThrow(NonNegIntException);
	expect(() => { course_user.course_user_id = '-1'; }).toThrow(NonNegIntException);
});

// tests parsing and handling of users

import { CourseUser, ParseableCourseUser } from 'src/common/models/users';
import { NonNegIntException, UserRole, UserRoleException } from 'src/common/models/parsers';

const default_course_user: ParseableCourseUser = {
	course_user_id: 0,
	user_id: 0,
	course_id: 0,
	role: UserRole.unknown
};

test('Create a CourseUser', () => {
	const course_user = new CourseUser();
	expect(course_user instanceof CourseUser).toBe(true);

	expect(course_user.toObject()).toStrictEqual(default_course_user);
});

test('Check that calling all_fields() and params() is correct', () => {
	const course_user_fields = ['course_user_id', 'course_id', 'user_id', 'role',
		'section', 'recitation'];
	const course_user = new CourseUser();

	expect(course_user.all_field_names.sort()).toStrictEqual(course_user_fields.sort());
	expect(course_user.param_fields.sort()).toStrictEqual([]);

	expect(CourseUser.ALL_FIELDS.sort()).toStrictEqual(course_user_fields.sort());

});

test('Check that cloning a CourseUser works', () => {
	const course_user = new CourseUser({ role: 'student' });
	const course_user2 = { ...default_course_user };
	course_user2.role = 'STUDENT';
	expect(course_user.clone().toObject()).toStrictEqual(course_user2);
	expect(course_user.clone() instanceof CourseUser).toBe(true);
});

test('create CourseUser with invalid role', () => {
	expect(() => {
		new CourseUser({ role: 'superhero' });
	}).toThrow(UserRoleException);
});

test('set fields of CourseUser', () => {
	const course_user = new CourseUser();

	course_user.role = 'student';
	expect(course_user.role).toBe('STUDENT');

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
	expect(course_user.role).toBe('STUDENT');

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

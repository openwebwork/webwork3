/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// tests parsing and handling of merged users

import { EmailParseException, NonNegIntException, UsernameParseException } from 'src/common/models/parsers';
import { CourseUser, DBCourseUser, ParseableDBCourseUser } from 'src/common/models/users';

describe('Testing Database and client-side Course Users', () => {

	const default_db_course_user: ParseableDBCourseUser = {
		course_user_id: 0,
		user_id: 0,
		course_id: 0,
		role: ''
	};

	describe('Testing Database course users', () => {

		test('Create a new database course user', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user).toBeInstanceOf(DBCourseUser);
			expect(db_course_user.toObject()).toStrictEqual(default_db_course_user);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const course_user_fields = ['course_user_id', 'course_id', 'user_id', 'role',
				'section', 'recitation'];
			const course_user = new DBCourseUser();

			expect(course_user.all_field_names.sort()).toStrictEqual(course_user_fields.sort());
			expect(course_user.param_fields.sort()).toStrictEqual([]);

			expect(DBCourseUser.ALL_FIELDS.sort()).toStrictEqual(course_user_fields.sort());

		});

		test('Check that cloning a DBCourseUser works', () => {
			const course_user = new DBCourseUser({ role: 'student' });
			const course_user2: ParseableDBCourseUser = { ...default_db_course_user };
			course_user2.role = 'STUDENT';
			expect(course_user.clone().toObject()).toStrictEqual(course_user2);
			expect(course_user.clone() instanceof DBCourseUser).toBe(true);
		});

		// TODO: update this test after model validity has been changed.
		test.skip('create DBCourseUser with invalid role', () => {
			expect(() => {
				new DBCourseUser({ role: 'superhero' });
			}).toThrow();
		});

		test('set fields of DBCourseUser', () => {
			const course_user = new DBCourseUser();

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

		test('set fields of DBCourseUser using set()', () => {
			const course_user = new DBCourseUser();
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

		test('set invalid user_id', () => {
			const course_user = new DBCourseUser();
			expect(() => { course_user.user_id = -1; }).toThrow(NonNegIntException);
			expect(() => { course_user.user_id = '-1'; }).toThrow(NonNegIntException);
		});

		test('set invalid course_id', () => {
			const course_user = new DBCourseUser();
			expect(() => { course_user.course_id = -1;}).toThrow(NonNegIntException);
			expect(() => { course_user.course_id = '-1'; }).toThrow(NonNegIntException);
		});

		test('set invalid course_user_id', () => {
			const course_user = new DBCourseUser();
			expect(() => { course_user.course_user_id =  -1; }).toThrow(NonNegIntException);
			expect(() => { course_user.course_user_id = '-1'; }).toThrow(NonNegIntException);
		});
	});

	describe('Testing course users', () => {

		const default_course_user = {
			course_user_id: 0,
			user_id: 0,
			course_id: 0,
			is_admin: false
		};

		test('Create a Valid CourseUser', () => {
			const course_user1 = new CourseUser();

			expect(course_user1).toBeInstanceOf(CourseUser);
			expect(course_user1.toObject()).toStrictEqual(default_course_user);

		});

		test('Check that calling all_fields() and params() is correct', () => {
			const course_user_fields = ['course_user_id', 'user_id', 'course_id', 'username',
				'is_admin', 'email', 'first_name', 'last_name', 'student_id', 'role',
				'section', 'recitation'];
			const course_user = new CourseUser();

			expect(course_user.all_field_names.sort()).toStrictEqual(course_user_fields.sort());
			expect(course_user.param_fields.sort()).toStrictEqual([]);
			expect(CourseUser.ALL_FIELDS.sort()).toStrictEqual(course_user_fields.sort());
		});

		test('Check that cloning a merged user works', () => {
			const course_user = new CourseUser();
			expect(course_user.clone().toObject()).toStrictEqual(default_course_user);
			expect(course_user.clone() instanceof CourseUser).toBe(true);
		});

		test('Invalid user_id', () => {
			expect(() => {
				new CourseUser({ username: 'test', user_id: -1 });
			}).toThrow(NonNegIntException);
			expect(() => {
				new CourseUser({ username: 'test', user_id: '-1' });
			}).toThrow(NonNegIntException);
			expect(() => {
				new CourseUser({ username: 'test', user_id: 'one' });
			}).toThrow(NonNegIntException);
		});

		test('Invalid username', () => {
			expect(() => {
				new CourseUser({ username: '@test' });
			}).toThrow(UsernameParseException);
			expect(() => {
				new CourseUser({ username: '123test' });
			}).toThrow(UsernameParseException);
			expect(() => {
				new CourseUser({ username: 'user name' });
			}).toThrow(UsernameParseException);
		});

		test('Invalid email', () => {
			expect(() => {
				new CourseUser({ username: 'test', email: 'bad email' });
			}).toThrow(EmailParseException);
			expect(() => {
				new CourseUser({ username: 'test', email: 'user@info@site.com' });
			}).toThrow(EmailParseException);
		});

		test('set fields of CourseUser', () => {
			const course_user = new CourseUser({ username: 'test' });
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

		test('set invalid user_id', () => {
			const course_user = new CourseUser({ username: 'test' });
			expect(() => {
				course_user.set({ user_id: -1 });
			}).toThrow(NonNegIntException);

			expect(() => {
				course_user.set({ user_id: '-1' });
			}).toThrow(NonNegIntException);

		});

		test('set invalid course_id', () => {
			const course_user = new CourseUser({ username: 'test' });
			expect(() => {
				course_user.set({ course_id: -1 });
			}).toThrow(NonNegIntException);
			expect(() => {
				course_user.set({ course_id: '-1' });
			}).toThrow(NonNegIntException);
		});

		test('set invalid course_user_id', () => {
			const course_user = new CourseUser({ username: 'test' });
			expect(() => {
				course_user.set({ course_user_id: -1 });
			}).toThrow(NonNegIntException);
			expect(() => {
				course_user.set({ course_user_id: '-1' });
			}).toThrow(NonNegIntException);
		});
	});
});

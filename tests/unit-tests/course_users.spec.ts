/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// tests parsing and handling of merged users

import { EmailParseException, NonNegIntException, UsernameParseException,
	UserRoleException, UserRole } from 'src/common/models/parsers';
import { CourseUser, DBCourseUser, ParseableDBCourseUser } from 'src/common/models/users';

describe('Testing Database and client-side Course Users', () => {
	describe('Creating a DBCourseUser', () => {
		const default_db_course_user = {
			course_user_id: 0,
			course_id: 0,
			user_id: 0,
			role: UserRole.unknown
		};
		test('Checking the creation of a dBCourseUser', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user).toBeInstanceOf(DBCourseUser);
			expect(db_course_user.toObject()).toStrictEqual(default_db_course_user);
			expect(db_course_user.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const db_course_user_fields = ['course_user_id', 'course_id', 'user_id', 'role',
				'section', 'recitation'];
			const course = new DBCourseUser();

			expect(course.all_field_names.sort()).toStrictEqual(db_course_user_fields.sort());
			expect(course.param_fields.sort()).toStrictEqual([]);
			expect(DBCourseUser.ALL_FIELDS.sort()).toStrictEqual(db_course_user_fields.sort());
		});

		test('Check that cloning works', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user.clone().toObject()).toStrictEqual(default_db_course_user);
			expect(db_course_user.clone()).toBeInstanceOf(DBCourseUser);
		});
	});

	describe('Updating a DBCourseUser', () => {
		test('Update DBCourseUser directly', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user.isValid()).toBe(true);

			db_course_user.course_user_id = 10;
			expect(db_course_user.course_user_id).toBe(10);

			db_course_user.user_id = 20;
			expect(db_course_user.user_id).toBe(20);

			db_course_user.course_id = 5;
			expect(db_course_user.course_id).toBe(5);

			db_course_user.role = UserRole.admin;
			expect(db_course_user.role).toBe(UserRole.admin);

			db_course_user.role = 'student';
			expect(db_course_user.role).toBe(UserRole.student);
		});

		test('Update DBCourseUser using the set method', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user.isValid()).toBe(true);

			db_course_user.set({ course_user_id: 10 });
			expect(db_course_user.course_user_id).toBe(10);

			db_course_user.set({ user_id: 20 });
			expect(db_course_user.user_id).toBe(20);

			db_course_user.set({ course_id: 5 });
			expect(db_course_user.course_id).toBe(5);

			db_course_user.set({ role: UserRole.admin });
			expect(db_course_user.role).toBe(UserRole.admin);

			db_course_user.set({ role: 'student' });
			expect(db_course_user.role).toBe(UserRole.student);
		});
	});

	describe('Checking for valid and invalid DBCourseUsers', () => {
		test('Checking for invalid course_user_id', () => {
			const db_course_user = new DBCourseUser();
			expect(db_course_user.isValid()).toBe(true);

			db_course_user.course_user_id = -3;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.course_user_id = 3.14;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.course_user_id = 7;
			expect(db_course_user.isValid()).toBe(true);

		});

		test('Checking for invalid user_id', () => {
			const db_course_user = new DBCourseUser();
			db_course_user.user_id = -5;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.user_id = 1.34;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.user_id = 5;
			expect(db_course_user.isValid()).toBe(true);
		});

		test('Checking for invalid course_id', () => {
			const db_course_user = new DBCourseUser();
			db_course_user.course_id = -9;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.course_id = 1.39;
			expect(db_course_user.isValid()).toBe(false);

			db_course_user.course_id = 9;
			expect(db_course_user.isValid()).toBe(true);
		});
	});

	describe('Testing course users', () => {

		const default_course_user = {
			course_user_id: 0,
			user_id: 0,
			course_id: 0,
			is_admin: false,
			username: '',
			email: '',
			first_name: '',
			last_name: '',
			role: 'UNKNOWN',
			student_id: ''
		};

		test('Create a Valid CourseUser', () => {
			const course_user = new CourseUser();
			expect(course_user).toBeInstanceOf(CourseUser);
			expect(course_user.toObject()).toStrictEqual(default_course_user);
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
			expect(course_user.clone()).toBeInstanceOf(CourseUser);

			// The default user is not valid (The username is the empty string.)
			expect(course_user.isValid()).toBe(false);
		});

		describe('Setting fields of a CourseUser', () => {
			test('Set CourseUser fields directly', () => {
				const course_user = new CourseUser();

				course_user.username = 'test2';
				expect(course_user.username).toBe('test2');

				course_user.email = 'test@site.com';
				expect(course_user.email).toBe('test@site.com');

				course_user.user_id = 15;
				expect(course_user.user_id).toBe(15);

				course_user.first_name = 'Homer';
				expect(course_user.first_name).toBe('Homer');

				course_user.last_name = 'Simpson';
				expect(course_user.last_name).toBe('Simpson');

				course_user.is_admin = true;
				expect(course_user.is_admin).toBe(true);

				course_user.student_id = '1234';
				expect(course_user.student_id).toBe('1234');

				course_user.course_user_id = 10;
				expect(course_user.course_user_id).toBe(10);

				course_user.course_id = 5;
				expect(course_user.course_id).toBe(5);

				course_user.role = UserRole.admin;
				expect(course_user.role).toBe(UserRole.admin);

				course_user.role = 'student';
				expect(course_user.role).toBe(UserRole.student);
			});

			test('Update CourseUser using the set method', () => {
				const course_user = new CourseUser({ username: 'homer' });
				expect(course_user.isValid()).toBe(true);

				course_user.set({ course_user_id: 10 });
				expect(course_user.course_user_id).toBe(10);

				course_user.set({ user_id: 20 });
				expect(course_user.user_id).toBe(20);

				course_user.set({ course_id: 5 });
				expect(course_user.course_id).toBe(5);

				course_user.set({ role: UserRole.admin });
				expect(course_user.role).toBe(UserRole.admin);

				course_user.set({ role: 'student' });
				expect(course_user.role).toBe(UserRole.student);

				course_user.set({ username: 'test2' });
				expect(course_user.username).toBe('test2');

				course_user.set({ email: 'test@site.com' });
				expect(course_user.email).toBe('test@site.com');

				course_user.set({ first_name: 'Homer' });
				expect(course_user.first_name).toBe('Homer');

				course_user.set({ last_name: 'Simpson' });
				expect(course_user.last_name).toBe('Simpson');

				course_user.set({ is_admin: true });
				expect(course_user.is_admin).toBe(true);

				course_user.set({ student_id: '1234' });
				expect(course_user.student_id).toBe('1234');
			});
		});

		describe('Testing for valid and invalid users.', () => {
			test('setting invalid user_id', () => {
				const user = new CourseUser({ username: 'homer' });
				expect(user.isValid()).toBe(true);

				user.user_id = -15;
				expect(user.isValid()).toBe(false);

				user.user_id = 1.23;
				expect(user.isValid()).toBe(false);
			});

			test('setting invalid course_user_id', () => {
				const course_user = new CourseUser({ username: 'homer' });
				expect(course_user.isValid()).toBe(true);

				course_user.course_user_id = -3;
				expect(course_user.isValid()).toBe(false);

				course_user.course_user_id = 3.14;
				expect(course_user.isValid()).toBe(false);

				course_user.course_user_id = 7;
				expect(course_user.isValid()).toBe(true);
			});

			test('setting invalid course_id', () => {
				const course_user = new CourseUser({ username: 'homer' });
				course_user.course_id = -9;
				expect(course_user.isValid()).toBe(false);

				course_user.course_id = 1.39;
				expect(course_user.isValid()).toBe(false);

				course_user.course_id = 9;
				expect(course_user.isValid()).toBe(true);
			});

			test('setting invalid email', () => {
				const user = new CourseUser({ username: 'test' });
				expect(user.isValid()).toBe(true);

				user.email = 'bad@email@address.com';
				expect(user.isValid()).toBe(false);
			});

			test('setting invalid username', () => {
				const user = new CourseUser({ username: 'my username' });
				expect(user.isValid()).toBe(false);
			});
		});
	});
});

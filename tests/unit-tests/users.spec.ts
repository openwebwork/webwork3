// tests parsing and handling of users

import { User } from 'src/common/models/users';

describe('Testing User and CourseUsers', () => {
	const default_user = {
		user_id: 0,
		username: '',
		is_admin: false,
		email: '',
		first_name: '',
		last_name: '',
		student_id: ''
	};

	describe('Create a new User', () => {
		test('Create a default User', () => {
			const user = new User();
			expect(user instanceof User).toBe(true);
			expect(user.toObject()).toStrictEqual(default_user);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const user_fields = ['user_id', 'username', 'is_admin', 'email', 'first_name',
				'last_name', 'student_id'];
			const user = new User();

			expect(user.all_field_names.sort()).toStrictEqual(user_fields.sort());
			expect(user.param_fields.sort()).toStrictEqual([]);
			expect(User.ALL_FIELDS.sort()).toStrictEqual(user_fields.sort());
		});

		test('Check that cloning a User works', () => {
			const user = new User();
			expect(user.clone().toObject()).toStrictEqual(default_user);
			expect(user.clone()).toBeInstanceOf(User);

			// The default user is not valid.  The username cannot be the empty string.
			expect(user.isValid()).toBe(false);
		});

	});

	describe('Setting fields of a User', () => {
		test('Set User field directly', () => {
			const user = new User();

			user.username = 'test2';
			expect(user.username).toBe('test2');

			user.email = 'test@site.com';
			expect(user.email).toBe('test@site.com');

			user.user_id = 15;
			expect(user.user_id).toBe(15);

			user.first_name = 'Homer';
			expect(user.first_name).toBe('Homer');

			user.last_name = 'Simpson';
			expect(user.last_name).toBe('Simpson');

			user.is_admin = true;
			expect(user.is_admin).toBe(true);

			user.student_id = '1234';
			expect(user.student_id).toBe('1234');

		});

		test('set fields using set() method', () => {
			const user = new User({ username: 'test' });

			user.set({ username: 'test2' });
			expect(user.username).toBe('test2');
			user.set({ email: 'test@site.com' });
			expect(user.email).toBe('test@site.com');

			user.set({ user_id: 15 });
			expect(user.user_id).toBe(15);

			user.set({ first_name: 'Homer' });
			expect(user.first_name).toBe('Homer');

			user.set({ last_name: 'Simpson' });
			expect(user.last_name).toBe('Simpson');

			user.set({ is_admin: true });
			expect(user.is_admin).toBe(true);

			user.set({ student_id: '1234' });
			expect(user.student_id).toBe('1234');
		});
	});

	describe('Testing for valid and invalid users.', () => {

		test('setting invalid email', () => {
			const user = new User({ username: 'test' });
			expect(user.isValid()).toBe(true);

			user.email = 'bad@email@address.com';
			expect(user.isValid()).toBe(false);
		});

		test('setting invalid user_id', () => {
			const user = new User({ username: 'test' });
			expect(user.isValid()).toBe(true);

			user.user_id = -15;
			expect(user.isValid()).toBe(false);
		});

		test('setting invalid username', () => {
			const user = new User({ username: 'my username' });
			expect(user.isValid()).toBe(false);
		});
	});
});

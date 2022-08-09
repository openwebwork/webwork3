// Tests for generic UserSets

import { DBUserSet, ParseableDBUserSet, UserSet } from 'src/common/models/user_sets';

describe('Test Generic User sets and Merged User sets', () => {

	const default_user_set: ParseableDBUserSet = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 0,
		set_type: 'UNKNOWN'
	};

	describe('Create User sets', () => {

		test('Create a generic DBUserSet', () => {
			const user_set = new DBUserSet();
			expect(user_set).toBeInstanceOf(DBUserSet);
			expect(user_set.toObject()).toStrictEqual(default_user_set);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const user_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_type',
				'set_version', 'set_visible'];
			const user_set = new DBUserSet();

			expect(user_set.all_field_names.sort()).toStrictEqual(user_set_fields.sort());
			expect(user_set.param_fields.sort()).toStrictEqual([]);
			expect(DBUserSet.ALL_FIELDS.sort()).toStrictEqual(user_set_fields.sort());
		});

		test('Check that cloning a generic DBUserSet works', () => {
			const user_set = new DBUserSet();
			expect(user_set.clone().toObject()).toStrictEqual(default_user_set);
			expect(user_set.clone()).toBeInstanceOf(DBUserSet);
		});

	});

	describe('Update Generic User Sets', () => {
		test('Set fields of user_set directly', () => {
			const user_set = new DBUserSet();
			user_set.user_set_id = 100;
			expect(user_set.user_set_id).toBe(100);

			user_set.set_id = 7;
			expect(user_set.set_id).toBe(7);

			user_set.course_user_id = 25;
			expect(user_set.course_user_id).toBe(25);

			user_set.set_version = 10;
			expect(user_set.set_version).toBe(10);
		});

		test('Set fields of user_set with set()', () => {
			const user_set = new DBUserSet();
			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);
		});

		test('Checking for valid and invalid user sets', () => {
			let user_set = new DBUserSet();
			expect(user_set.isValid()).toBe(true);

			user_set = new DBUserSet({ user_set_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new DBUserSet({ set_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new DBUserSet({ course_user_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new DBUserSet({ set_version: 3.432 });
			expect(user_set.isValid()).toBe(false);
		});
	});

	describe('Create a new Merged User Set', () => {
		test('Create a generic UserSet', () => {
			const user_set = new UserSet();
			expect(user_set).toBeInstanceOf(UserSet);

			const user_set_defaults = {
				user_set_id: 0,
				set_id: 0,
				course_user_id: 0,
				set_version: 0,
				set_name: '',
				username: ''
			};
			// Since UserSet has 'set_params' and 'set_dates' as placeholds for subclasses,
			// don't call them in the toObject.
			// TODO: find a better way to handle this.
			const fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'set_visible',
				'set_name', 'username'];
			expect(user_set.toObject(fields)).toStrictEqual(user_set_defaults);
		});
	});

	describe('Update merged user sets', () => {
		test('Set fields of User Sets directly', () => {
			const user_set = new UserSet();
			user_set.user_set_id = 100;
			expect(user_set.user_set_id).toBe(100);

			user_set.set_id = 7;
			expect(user_set.set_id).toBe(7);

			user_set.course_user_id = 25;
			expect(user_set.course_user_id).toBe(25);

			user_set.set_version = 10;
			expect(user_set.set_version).toBe(10);

			user_set.set_visible = true;
			expect(user_set.set_visible).toBe(true);

			user_set.set_name = 'HW #1';
			expect(user_set.set_name).toBe('HW #1');

			user_set.username = 'user';
			expect(user_set.username).toBe('user');

		});

		test('Set fields of Merged User Sets with set()', () => {
			const user_set = new UserSet();
			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);

			user_set.set({ set_visible: true });
			expect(user_set.set_visible).toBeTruthy();

			user_set.set({ set_name: 'HW #1' });
			expect(user_set.set_name).toBe('HW #1');

			user_set.set({ username: 'user' });
			expect(user_set.username).toBe('user');

		});

		test('Checking for valid and invalid User Sets', () => {
			let user_set = new UserSet();
			// The default user_set is not valid because it needs a username and set_name.
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer', set_name: 'HW #1' });
			expect(user_set.isValid()).toBe(true);

			user_set = new UserSet({ username: 'homer@msn.com', set_name: 'HW #1' });
			expect(user_set.isValid()).toBe(true);

			user_set = new UserSet({ username: 'homer rules', set_name: 'HW #1' });
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer' });
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer', set_name: 'HW #1', user_set_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer', set_name: 'HW #1', set_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer', set_name: 'HW #1', user_id: -1 });
			expect(user_set.isValid()).toBe(false);

			user_set = new UserSet({ username: 'homer', set_name: 'HW #1', set_version: 3.14 });
			expect(user_set.isValid()).toBe(false);
		});
	});
});

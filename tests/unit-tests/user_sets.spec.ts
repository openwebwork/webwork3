/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { BooleanParseException, NonNegIntException, UsernameParseException } from 'src/common/models/parsers';
import { DBUserSet, ParseableDBUserSet, UserSet } from 'src/common/models/user_sets';

describe('Test Generic User sets and Merged User sets', () => {

	const default_user_set: ParseableDBUserSet = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_visible: false,
		set_version: 1,
		set_type: 'UNKNOWN'
	};

	describe('Create User sets', () => {

		test('Create a generic DBUserSet', () => {
			const user_set = new DBUserSet();
			expect(user_set).toBeInstanceOf(DBUserSet);
			expect(user_set.toObject()).toStrictEqual(default_user_set);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const user_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_type', 'set_version', 'set_visible'];
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

			user_set.user_set_id = '20';
			expect(user_set.user_set_id).toBe(20);

			user_set.set_id = 7;
			expect(user_set.set_id).toBe(7);

			user_set.set_id = '9';
			expect(user_set.set_id).toBe(9);

			user_set.course_user_id = 25;
			expect(user_set.course_user_id).toBe(25);

			user_set.course_user_id = '18';
			expect(user_set.course_user_id).toBe(18);

			user_set.set_version = 10;
			expect(user_set.set_version).toBe(10);

			user_set.set_version = '22';
			expect(user_set.set_version).toBe(22);

		});

		test('Set fields of user_set with set()', () => {
			const user_set = new DBUserSet();
			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ user_set_id: '33' });
			expect(user_set.user_set_id).toBe(33);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ set_id: '78' });
			expect(user_set.set_id).toBe(78);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ course_user_id: '34' });
			expect(user_set.course_user_id).toBe(34);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);

			user_set.set({ set_version: '54' });
			expect(user_set.set_version).toBe(54);

		});

		test('Checking that setting invalid fields throws errors', () => {
			const user_set = new DBUserSet();
			expect(() => { user_set.user_set_id = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.user_set_id = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.user_set_id = 'one';}).toThrow(NonNegIntException);

			expect(() => { user_set.set_id = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.set_id = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.set_id = 'one';}).toThrow(NonNegIntException);

			expect(() => { user_set.course_user_id = -10;}).toThrow(NonNegIntException);
			expect(() => { user_set.course_user_id = '-10';}).toThrow(NonNegIntException);
			expect(() => { user_set.course_user_id = 'ten';}).toThrow(NonNegIntException);

			expect(() => { user_set.set_version = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.set_version = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.set_version = 'one';}).toThrow(NonNegIntException);

		});

		test('Checking that setting invalid fields with set() throws errors', () => {
			const user_set = new DBUserSet();
			expect(() => { user_set.set({ user_set_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ user_set_id: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ user_set_id: 'one' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ set_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_id: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_id: 'one' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ course_user_id: -10 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ course_user_id: '-10' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ course_user_id: 'ten' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ set_version: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_version: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_version: 'one' });}).toThrow(NonNegIntException);

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
				set_version: 1,
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
		test('Set fields of Merged User Sets directly', () => {
			const user_set = new UserSet();
			user_set.user_set_id = 100;
			expect(user_set.user_set_id).toBe(100);

			user_set.user_set_id = '20';
			expect(user_set.user_set_id).toBe(20);

			user_set.set_id = 7;
			expect(user_set.set_id).toBe(7);

			user_set.set_id = '9';
			expect(user_set.set_id).toBe(9);

			user_set.course_user_id = 25;
			expect(user_set.course_user_id).toBe(25);

			user_set.course_user_id = '18';
			expect(user_set.course_user_id).toBe(18);

			user_set.set_version = 10;
			expect(user_set.set_version).toBe(10);

			user_set.set_version = '22';
			expect(user_set.set_version).toBe(22);

			user_set.set_visible = true;
			expect(user_set.set_visible).toBeTruthy();

			user_set.set_visible = '0';
			expect(user_set.set_visible).toBeFalsy();

			user_set.set_visible = 'true';
			expect(user_set.set_visible).toBeTruthy();

			user_set.set_name = 'HW #1';
			expect(user_set.set_name).toBe('HW #1');

			user_set.username = 'user';
			expect(user_set.username).toBe('user');

		});

		test('Set fields of Merged User Sets with set()', () => {
			const user_set = new UserSet();
			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ user_set_id: '33' });
			expect(user_set.user_set_id).toBe(33);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ set_id: '78' });
			expect(user_set.set_id).toBe(78);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ course_user_id: '34' });
			expect(user_set.course_user_id).toBe(34);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);

			user_set.set({ set_version: '54' });
			expect(user_set.set_version).toBe(54);

			user_set.set({ set_visible: true });
			expect(user_set.set_visible).toBeTruthy();

			user_set.set({ set_visible: '0' });
			expect(user_set.set_visible).toBeFalsy();

			user_set.set({ set_visible: 'true' });
			expect(user_set.set_visible).toBeTruthy();

			user_set.set({ set_name: 'HW #1' });
			expect(user_set.set_name).toBe('HW #1');

			user_set.set({ username: 'user' });
			expect(user_set.username).toBe('user');

		});

		test('Checking that setting invalid fields throws errors', () => {
			const user_set = new UserSet();
			expect(() => { user_set.user_set_id = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.user_set_id = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.user_set_id = 'one';}).toThrow(NonNegIntException);

			expect(() => { user_set.set_id = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.set_id = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.set_id = 'one';}).toThrow(NonNegIntException);

			expect(() => { user_set.course_user_id = -10;}).toThrow(NonNegIntException);
			expect(() => { user_set.course_user_id = '-10';}).toThrow(NonNegIntException);
			expect(() => { user_set.course_user_id = 'ten';}).toThrow(NonNegIntException);

			expect(() => { user_set.set_version = -1;}).toThrow(NonNegIntException);
			expect(() => { user_set.set_version = '-1';}).toThrow(NonNegIntException);
			expect(() => { user_set.set_version = 'one';}).toThrow(NonNegIntException);

			expect(() => { user_set.set_visible = 2; }).toThrow(BooleanParseException);
			expect(() => { user_set.set_visible = 'FalSe'; }).toThrow(BooleanParseException);

			expect(() => { user_set.username = '1234user'; }).toThrow(UsernameParseException);
			expect(() => { user_set.username = 'bad username'; }).toThrow(UsernameParseException);

		});

		test('Checking that setting invalid fields with set() throws errors', () => {
			const user_set = new UserSet();
			expect(() => { user_set.set({ user_set_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ user_set_id: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ user_set_id: 'one' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ set_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_id: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_id: 'one' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ course_user_id: -10 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ course_user_id: '-10' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ course_user_id: 'ten' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ set_version: -1 });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_version: '-1' });}).toThrow(NonNegIntException);
			expect(() => { user_set.set({ set_version: 'one' });}).toThrow(NonNegIntException);

			expect(() => { user_set.set({ set_visible: 2 }); }).toThrow(BooleanParseException);
			expect(() => { user_set.set({ set_visible: 'FalSe' }); }).toThrow(BooleanParseException);

			expect(() => { user_set.set({ username: '1234user' }); }).toThrow(UsernameParseException);
			expect(() => { user_set.set({ username: 'bad username' }); }).toThrow(UsernameParseException);

		});
	});
});

/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { HomeworkSet } from 'src/common/models/problem_sets';
import { CourseUser } from 'src/common/models/users';
import { DBUserHomeworkSet, UserSet, mergeUserSet, ParseableDBUserHomeworkSet,
	ParseableUserHomeworkSet, UserHomeworkSet, DBUserSet, UserHomeworkSetParams,
	UserHomeworkSetDates } from 'src/common/models/user_sets';

describe('Test user Homework sets', () => {
	const default_db_user_homework_set: ParseableDBUserHomeworkSet = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_type: 'HW',
		set_params: {},
		set_dates: {}
	};

	describe('Create a User Homework Set', () => {
		test('Create a DBUserHomeworkSet', () => {
			const user_hw = new DBUserHomeworkSet();
			expect(user_hw).toBeInstanceOf(DBUserHomeworkSet);
			expect(user_hw).toBeInstanceOf(DBUserSet);
			expect(user_hw.toObject()).toStrictEqual(default_db_user_homework_set);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const hw_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'set_visible', 'set_params', 'set_dates', 'set_type'];
			const hw = new DBUserHomeworkSet();

			expect(hw.all_field_names.sort()).toStrictEqual(hw_fields.sort());
			expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);
			expect(DBUserHomeworkSet.ALL_FIELDS.sort()).toStrictEqual(hw_fields.sort());
		});

		test('Check that cloning a DBUserHomeworkSet works', () => {
			const user_hw = new DBUserHomeworkSet();
			expect(user_hw.clone().toObject()).toStrictEqual(default_db_user_homework_set);
			expect(user_hw.clone()).toBeInstanceOf(DBUserHomeworkSet);
		});
	});

	describe('Update the fields of a User Homework Set', () => {
		test('Set fields of user_set directly', () => {
			const user_set = new DBUserHomeworkSet();
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
			const user_set = new DBUserHomeworkSet();
			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);
		});
	});

	describe('Test UserHomeworkParams', () => {
		test('Creating user homework params', () => {
			const params = new UserHomeworkSetParams();
			expect(params).toBeInstanceOf(UserHomeworkSetParams);
			expect(params.toObject()).toStrictEqual(default_db_user_homework_set.set_params);
		});

		test('Call all_fields() and params() of UserHomeworkSetParams', () => {
			const user_hw_param_fields = ['hide_hint', 'hardcopy_header', 'set_header', 'description'];
			const user_hw_params = new UserHomeworkSetParams();

			expect(user_hw_params.all_field_names.sort()).toStrictEqual(user_hw_param_fields.sort());
			expect(user_hw_params.param_fields.sort()).toStrictEqual([]);
			expect(UserHomeworkSetParams.ALL_FIELDS.sort()).toStrictEqual(user_hw_param_fields.sort());
		});

		test('Clone a UserHomeworkSetParam', () => {
			const user_hw_params = new UserHomeworkSetParams();
			expect(user_hw_params.clone().toObject()).toStrictEqual(default_db_user_homework_set.set_params);
			expect(user_hw_params.clone()).toBeInstanceOf(UserHomeworkSetParams);
		});
	});

	describe('Update UserHomeworkParams', () => {
		test('Update UserHomeworkParams directly', () => {
			const params = new UserHomeworkSetParams();
			params.hide_hint = true;
			expect(params.hide_hint).toBe(true);

			params.hide_hint = false;
			expect(params.hide_hint).toBe(false);

			params.hide_hint = undefined;
			expect(params.hide_hint).toBeUndefined();

			params.hardcopy_header = 'this is the hardcopy header';
			expect(params.hardcopy_header).toBe('this is the hardcopy header');

			params.hardcopy_header = undefined;
			expect(params.hardcopy_header).toBeUndefined();

			params.set_header = 'this is the set header';
			expect(params.set_header).toBe('this is the set header');

			params.set_header = undefined;
			expect(params.set_header).toBeUndefined();

			params.description = 'this is the description';
			expect(params.description).toBe('this is the description');

			params.description = undefined;
			expect(params.description).toBeUndefined();
		});

		test('Update the User Homework Sets Params using the set method.', () => {
			const params = new UserHomeworkSetParams();
			params.set({ hide_hint: true });
			expect(params.hide_hint).toBe(true);

			params.set({ hide_hint: false });
			expect(params.hide_hint).toBe(false);

			params.set({ hide_hint: undefined });
			expect(params.hide_hint).toBeUndefined();

			params.set({ hardcopy_header: 'this is the hardcopy header' });
			expect(params.hardcopy_header).toBe('this is the hardcopy header');

			params.set({ hardcopy_header: undefined });
			expect(params.hardcopy_header).toBeUndefined();

			params.set({ set_header: 'this is the set header' });
			expect(params.set_header).toBe('this is the set header');

			params.set({ set_header: undefined });
			expect(params.set_header).toBeUndefined();

			params.set({ description: 'this is the description' });
			expect(params.description).toBe('this is the description');

			params.set({ description: undefined });
			expect(params.description).toBeUndefined();
		});

		// No objects are invalid, so no testing is done.  If the model is updated
		// a section testing the validity of the UserHomeworkParams should occur here.
	});

	describe('Test UserHomeworkDates', () => {
		test('Creating user homework dates', () => {
			const dates = new UserHomeworkSetDates();
			expect(dates).toBeInstanceOf(UserHomeworkSetDates);
			expect(dates.toObject()).toStrictEqual(default_db_user_homework_set.set_dates);
		});

		test('Call all_fields() and params() of UserHomeworkSetDates', () => {
			const user_hw_dates_fields = ['open', 'reduced_scoring', 'due', 'answer', 'enable_reduced_scoring'];
			const user_hw_dates = new UserHomeworkSetDates();

			expect(user_hw_dates.all_field_names.sort()).toStrictEqual(user_hw_dates_fields.sort());
			expect(user_hw_dates.param_fields.sort()).toStrictEqual([]);
			expect(UserHomeworkSetDates.ALL_FIELDS.sort()).toStrictEqual(user_hw_dates_fields.sort());
		});

		test('Clone a UserHomeworkSetParam', () => {
			const user_hw_dates = new UserHomeworkSetDates();
			expect(user_hw_dates.clone().toObject()).toStrictEqual(default_db_user_homework_set.set_dates);
			expect(user_hw_dates.clone()).toBeInstanceOf(UserHomeworkSetDates);
		});
	});

	describe('Update UserHomeworkDates', () => {
		test('Update UserHomeworkDates directly', () => {
			const dates = new UserHomeworkSetDates();
			dates.open = 100;
			expect(dates.open).toBe(100);

			dates.open = undefined;
			expect(dates.open).toBeUndefined();

			dates.reduced_scoring = 200;
			expect(dates.reduced_scoring).toBe(200);

			dates.reduced_scoring = undefined;
			expect(dates.reduced_scoring).toBeUndefined();

			dates.due = 300;
			expect(dates.due).toBe(300);

			dates.due = undefined;
			expect(dates.due).toBeUndefined();

			dates.answer = 400;
			expect(dates.answer).toBe(400);

			dates.answer = undefined;
			expect(dates.answer).toBeUndefined();

			dates.enable_reduced_scoring = true;
			expect(dates.enable_reduced_scoring).toBe(true);

			dates.enable_reduced_scoring = false;
			expect(dates.enable_reduced_scoring).toBe(false);

			dates.enable_reduced_scoring = undefined;
			expect(dates.enable_reduced_scoring).toBeUndefined();

		});

		test('Update the User Homework Sets dates using the set method.', () => {
			const dates = new UserHomeworkSetDates();
			dates.set({ open: 100 });
			expect(dates.open).toBe(100);

			dates.set({ open: undefined });
			expect(dates.open).toBeUndefined();

			dates.set({ reduced_scoring: 200 });
			expect(dates.reduced_scoring).toBe(200);

			dates.set({ reduced_scoring: undefined });
			expect(dates.reduced_scoring).toBeUndefined();

			dates.set({ due: 300 });
			expect(dates.due).toBe(300);

			dates.set({ due: undefined });
			expect(dates.due).toBeUndefined();

			dates.set({ answer: 400 });
			expect(dates.answer).toBe(400);

			dates.set({ answer: undefined });
			expect(dates.answer).toBeUndefined();
		});
	});

	describe('Validity of UserHomeworkSetDates', () => {
		test('Testing the validity of UserHomeworkSet dates', () => {
			const dates = new UserHomeworkSetDates();
			expect(dates.isValid()).toBe(true);

			dates.set({ open: 100, due: 200, answer: 300 });
			expect(dates.isValid()).toBe(true);

			dates.set({ open: 100, reduced_scoring: 0, due: 200, answer: 300 });
			expect(dates.isValid()).toBe(true);

			dates.set({ open: 100, reduced_scoring: 150, due: 200, answer: 300, enable_reduced_scoring: true });
			expect(dates.isValid()).toBe(true);

			dates.set({ open: 100, reduced_scoring: 50, enable_reduced_scoring: true });
			expect(dates.isValid()).toBe(false);

			dates.set({ open: 100, reduced_scoring: 50, enable_reduced_scoring: false });
			expect(dates.isValid()).toBe(true);

			dates.set({ open: 100, due: 50 });
			expect(dates.isValid()).toBe(false);

			dates.set({ open: 100, answer: 50 });
			expect(dates.isValid()).toBe(false);

			dates.set({ reduced_scoring: 100, due: 50, enable_reduced_scoring: true });
			expect(dates.isValid()).toBe(false);

			dates.set({ reduced_scoring: 100, answer: 50, enable_reduced_scoring: true });
			expect(dates.isValid()).toBe(false);

			dates.set({ due: 300, answer: 200 });
			expect(dates.isValid()).toBe(false);

		});
	});

	describe('Create User Homework Sets', () => {

		const default_user_homework_set: ParseableUserHomeworkSet = {
			user_id: 0,
			user_set_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_name: '',
			username: '',
			set_type: 'HW',
			set_params: { hide_hint: false, description: '', hardcopy_header: '', set_header: '' },
			set_dates: { open: 0, reduced_scoring: 0, due: 0, answer: 0, enable_reduced_scoring: false }
		};

		test('Create a UserHomeworkSet', () => {
			const user_hw = new UserHomeworkSet();
			expect(user_hw).toBeInstanceOf(UserHomeworkSet);
			expect(user_hw).toBeInstanceOf(UserSet);
			expect(user_hw.toObject()).toStrictEqual(default_user_homework_set);
		});

		test('Call all_fields() and params() of UserHomeworkSet', () => {
			const user_hw_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'set_type',
				'user_id', 'set_visible', 'set_name', 'username', 'set_params', 'set_dates'];
			const hw = new UserHomeworkSet();

			expect(hw.all_field_names.sort()).toStrictEqual(user_hw_fields.sort());
			expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);
			expect(UserHomeworkSet.ALL_FIELDS.sort()).toStrictEqual(user_hw_fields.sort());
		});

		test('Clone a UserHomeworkSet', () => {
			const hw = new UserHomeworkSet();
			expect(hw.clone().toObject()).toStrictEqual(default_user_homework_set);
			expect(hw.clone()).toBeInstanceOf(UserHomeworkSet);
		});
	});

	describe('Update user homework sets', () => {
		test('Set fields of Homework Set directly', () => {
			const user_set = new UserHomeworkSet();

			expect(user_set.set_type).toBe('HW');

			user_set.user_set_id = 100;
			expect(user_set.user_set_id).toBe(100);

			user_set.set_id = 7;
			expect(user_set.set_id).toBe(7);

			user_set.course_user_id = 25;
			expect(user_set.course_user_id).toBe(25);

			user_set.user_id = 15;
			expect(user_set.user_id).toBe(15);

			user_set.set_version = 10;
			expect(user_set.set_version).toBe(10);

			user_set.set_visible = true;
			expect(user_set.set_visible).toBe(true);

			user_set.set_name = 'HW #1';
			expect(user_set.set_name).toBe('HW #1');

			user_set.username = 'user';
			expect(user_set.username).toBe('user');
		});

		test('Set fields of Homework Set use the set method', () => {
			const user_set = new UserHomeworkSet();
			expect(user_set.set_type).toBe('HW');

			user_set.set({ user_set_id: 100 });
			expect(user_set.user_set_id).toBe(100);

			user_set.set({ set_id: 7 });
			expect(user_set.set_id).toBe(7);

			user_set.set({ course_user_id: 25 });
			expect(user_set.course_user_id).toBe(25);

			user_set.set({ user_id: 15 });
			expect(user_set.user_id).toBe(15);

			user_set.set({ set_version: 10 });
			expect(user_set.set_version).toBe(10);

			user_set.set({ set_visible: true });
			expect(user_set.set_visible).toBe(true);

			user_set.set({ set_name: 'HW #1' });
			expect(user_set.set_name).toBe('HW #1');

			user_set.set({ username: 'user' });
			expect(user_set.username).toBe('user');
		});

	});

	describe('Validity of a UserHomeworkSet', () => {
		test('Test the validity of a UserHomeworkSet', () => {
			let user_hw = new UserHomeworkSet();
			// This must have a valid username and set_name.
			expect(user_hw.isValid()).toBe(false);

			user_hw = new UserHomeworkSet({ username: 'homer', set_name: 'HW #1' });
			expect(user_hw.isValid()).toBe(true);

			user_hw = new UserHomeworkSet({ username: 'homer', set_name: 'HW #1', set_id: -1 });
			expect(user_hw.isValid()).toBe(false);

			user_hw = new UserHomeworkSet({ username: 'homer', set_name: 'HW #1', user_id: 1.34 });
			expect(user_hw.isValid()).toBe(false);

			user_hw = new UserHomeworkSet({ username: 'homer', set_name: 'HW #1', user_set_id: -32 });
			expect(user_hw.isValid()).toBe(false);
		});
	});

	// Note: the UserHomeworkSet params and dates are thoroughly tested in hw_sets.spec.ts
	// since they are the same models as in a HomeworkSet.

	describe('Test UserHomeworkSet dates', () => {

		test('Set dates of a UserHomeworkSet', () => {
			const user_hw = new UserHomeworkSet();
			user_hw.set_dates.open = 100;
			expect(user_hw.set_dates.open).toBe(100);

			user_hw.set_dates.due = 800;
			expect(user_hw.set_dates.due).toBe(800);

			user_hw.set_dates.answer = 1000;
			expect(user_hw.set_dates.answer).toBe(1000);

			user_hw.set_dates.set({
				open: 600,
				due: 700,
				answer: 800
			});

			expect(user_hw.set_dates.toObject()).toStrictEqual({
				open: 600,
				reduced_scoring: 0,
				due: 700,
				answer: 800,
				enable_reduced_scoring: false
			});

			expect(user_hw.set_dates.isValid()).toBe(true);

			user_hw.set_dates.enable_reduced_scoring = true;
			expect(user_hw.set_dates.isValid()).toBe(false);

			user_hw.set_dates.reduced_scoring = 650;
			expect(user_hw.set_dates.reduced_scoring).toBe(650);
			expect(user_hw.set_dates.isValid()).toBe(true);
		});
	});

	describe('Merging a problem set, user set and user', () => {
		const user = new CourseUser({
			user_id: 99,
			course_user_id: 299,
			username: 'homer',
			first_name: 'Homer',
			last_name: 'Simpson',
			email: 'homer@msn.com'
		});
		const hw = new HomeworkSet({
			set_name: 'HW #1',
			set_id: 99,
			set_dates: {
				open: 100,
				due: 200,
				answer: 300
			}
		});
		const db_user_set = new DBUserHomeworkSet({
			set_id: 99,
			course_user_id: 299
		});

		test('created a user homework set by merging db homework and user sets.', () => {
			const expected_user_hw = new UserHomeworkSet({
				user_id: 99,
				course_user_id: 299,
				username: 'homer',
				set_name: 'HW #1',
				set_id: 99,
				set_visible: false,
				set_dates: {
					open: 100,
					due: 200,
					answer: 300
				}
			});
			const merged_set = mergeUserSet(hw, db_user_set, user);
			expect(expected_user_hw).toStrictEqual(merged_set);
		});

		test('create a user homework set with complete set of user set dates', () => {
			db_user_set.set_dates.set({
				open: 150,
				due: 200,
				answer: 500
			});
			const expected_user_hw = new UserHomeworkSet({
				user_id: 99,
				course_user_id: 299,
				username: 'homer',
				set_name: 'HW #1',
				set_id: 99,
				set_visible: false,
				set_dates: {
					open: 150,
					due: 200,
					answer: 500
				}
			});
			const user_set = mergeUserSet(hw, db_user_set, user) as UserHomeworkSet;
			expect(expected_user_hw).toStrictEqual(user_set);

			// check that if the enable_reduced_scoring is flipped on, then the dates are
			// no longer valid
			user_set.set_dates.enable_reduced_scoring = true;
			expect(user_set.set_dates.isValid()).toBe(false);

			// but then if the reduced_scoring date is set to the due date it will be
			user_set.set_dates.reduced_scoring = user_set.set_dates.due;
			expect(user_set.set_dates.isValid()).toBe(true);

		});

		test('created a user homework set with reduced scoring dates', () => {
			hw.set_dates.enable_reduced_scoring = true;
			hw.set_dates.reduced_scoring = 175;
			const expected_user_hw = new UserHomeworkSet({
				user_id: 99,
				course_user_id: 299,
				username: 'homer',
				set_name: 'HW #1',
				set_id: 99,
				set_visible: false,
				set_dates: {
					open: 150,
					reduced_scoring: 175,
					due: 200,
					answer: 500,
					enable_reduced_scoring: true
				}
			});
			const hw_set = mergeUserSet(hw, db_user_set, user);
			expect(expected_user_hw).toStrictEqual(hw_set);
		});
	});
});

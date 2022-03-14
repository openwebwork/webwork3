/**
 * @jest-environment jsdom
 */

// Test Merged User Sets

import { BooleanParseException, NonNegIntException, UsernameParseException } from 'src/common/models/parsers';
import { MergedUserHomeworkSet, MergedUserQuiz, MergedUserSet,
	MergedUserReviewSet, ParseableMergedUserHomeworkSet } from 'src/common/models/user_sets';

test('Create a generic MergedUserSet', () => {
	const user_set = new MergedUserSet();
	expect(user_set instanceof MergedUserSet).toBe(true);

	const user_set_defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_visible: false,
		set_name: '',
		username: ''
	};
	// Since MergedUserSet has 'set_params' and 'set_dates' as placeholds for subclasses,
	// don't call them in the toObject.
	// TODO: find a better way to handle this.
	const fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'set_visible',
		'set_name', 'username'];
	expect(user_set.toObject(fields)).toStrictEqual(user_set_defaults);
});

test('Set fields of Merged User Sets directly', () => {
	const user_set = new MergedUserSet();
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
	expect(user_set.set_visible).toBe(true);

	user_set.set_visible = '0';
	expect(user_set.set_visible).toBe(false);

	user_set.set_visible = 'true';
	expect(user_set.set_visible).toBe(true);

	user_set.set_name = 'HW #1';
	expect(user_set.set_name).toBe('HW #1');

	user_set.username = 'user';
	expect(user_set.username).toBe('user');

});

test('Set fields of Merged User Sets with set()', () => {
	const user_set = new MergedUserSet();
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
	expect(user_set.set_visible).toBe(true);

	user_set.set({ set_visible: '0' });
	expect(user_set.set_visible).toBe(false);

	user_set.set({ set_visible: 'true' });
	expect(user_set.set_visible).toBe(true);

	user_set.set({ set_name: 'HW #1' });
	expect(user_set.set_name).toBe('HW #1');

	user_set.set({ username: 'user' });
	expect(user_set.username).toBe('user');

});

test('Checking that setting invalid fields throws errors', () => {
	const user_set = new MergedUserSet();
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
	const user_set = new MergedUserSet();
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

const default_merged_homework_set: ParseableMergedUserHomeworkSet = {
	user_set_id: 0,
	set_id: 0,
	course_user_id: 0,
	set_version: 1,
	set_name: '',
	username: '',
	set_visible: false,
	set_params: { enable_reduced_scoring: false },
	set_dates: { open: 0, due: 0, reduced_scoring: 0, answer: 0 }
};

test('Create a MergedUserHomeworkSet', () => {
	const user_hw = new MergedUserHomeworkSet();
	expect(user_hw instanceof MergedUserHomeworkSet).toBe(true);
	expect(user_hw instanceof MergedUserSet).toBe(true);

	expect(user_hw.toObject()).toStrictEqual(default_merged_homework_set);
});

test('Check that calling all_fields() and params() is correct', () => {
	const merged_user_hw_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_visible', 'set_name', 'username', 'set_params', 'set_dates'];
	const hw = new MergedUserHomeworkSet();

	expect(hw.all_field_names.sort()).toStrictEqual(merged_user_hw_fields.sort());
	expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

	expect(MergedUserHomeworkSet.ALL_FIELDS.sort()).toStrictEqual(merged_user_hw_fields.sort());

});

test('Check that cloning a Quiz works', () => {
	const hw = new MergedUserHomeworkSet();
	expect(hw.clone().toObject()).toStrictEqual(default_merged_homework_set);
	expect(hw.clone() instanceof MergedUserHomeworkSet).toBe(true);
});

test('Set fields of Merged Homework Set directly', () => {
	const user_set = new MergedUserHomeworkSet();
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
	expect(user_set.set_visible).toBe(true);

	user_set.set_visible = '0';
	expect(user_set.set_visible).toBe(false);

	user_set.set_visible = 'true';
	expect(user_set.set_visible).toBe(true);

	user_set.set_name = 'HW #1';
	expect(user_set.set_name).toBe('HW #1');

	user_set.username = 'user';
	expect(user_set.username).toBe('user');

});

test('Set params of a MergedUserHomeworkSet', () => {
	const user_hw = new MergedUserHomeworkSet();
	user_hw.set_params.enable_reduced_scoring = true;
	expect(user_hw.set_params.enable_reduced_scoring).toBe(true);

	user_hw.set_params.enable_reduced_scoring = '0';
	expect(user_hw.set_params.enable_reduced_scoring).toBe(false);

	user_hw.set_params.enable_reduced_scoring = 'true';
	expect(user_hw.set_params.enable_reduced_scoring).toBe(true);

});

test('Set dates of a MergedUserHomeworkSet', () => {
	const user_hw = new MergedUserHomeworkSet();
	user_hw.set_dates.open = 100;
	expect(user_hw.set_dates.open).toBe(100);

	user_hw.set_dates.set({
		open: 600,
		due: 700,
		answer: 800
	});

	expect(user_hw.set_dates.toObject()).toStrictEqual({
		open: 600,
		reduced_scoring: 0,
		due: 700,
		answer: 800
	});

	expect(user_hw.hasValidDates()).toBe(true);

	user_hw.set_params.enable_reduced_scoring = true;
	expect(user_hw.hasValidDates()).toBe(false);

	user_hw.set_dates.reduced_scoring = 650;
	expect(user_hw.hasValidDates()).toBe(true);

});

test('Create a MergedUserQuiz', () => {
	const user_quiz = new MergedUserQuiz();
	expect(user_quiz instanceof MergedUserHomeworkSet).toBe(false);
	expect(user_quiz instanceof MergedUserQuiz).toBe(true);
	expect(user_quiz instanceof MergedUserSet).toBe(true);

	const defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_name: '',
		username: '',
		set_visible: false,
		set_params: { timed: false, quiz_duration: 0 },
		set_dates: { open: 0, due: 0, answer: 0 }
	};
	expect(user_quiz.toObject()).toStrictEqual(defaults);
});

test('Set params of a MergedUserQuiz', () => {
	const user_quiz = new MergedUserQuiz();

	user_quiz.set_params.timed = true;
	expect(user_quiz.set_params.timed).toBe(true);

	user_quiz.set_params.timed = '0';
	expect(user_quiz.set_params.timed).toBe(false);

	user_quiz.set_params.timed = 'true';
	expect(user_quiz.set_params.timed).toBe(true);

});

test('Set dates of a MergedUserQuiz', () => {
	const user_quiz = new MergedUserQuiz();
	user_quiz.set_dates.open = 100;
	expect(user_quiz.set_dates.open).toBe(100);

	user_quiz.set_dates.set({
		open: 600,
		due: 700,
		answer: 800
	});

	expect(user_quiz.set_dates.toObject()).toStrictEqual({
		open: 600,
		due: 700,
		answer: 800
	});

	expect(user_quiz.hasValidDates()).toBe(true);

	user_quiz.set_dates.due = 1000;
	expect(user_quiz.hasValidDates()).toBe(false);

});

test('Create a MergedUserReviewSet', () => {
	const user_review_set = new MergedUserReviewSet();
	expect(user_review_set instanceof MergedUserHomeworkSet).toBe(false);
	expect(user_review_set instanceof MergedUserReviewSet).toBe(true);
	expect(user_review_set instanceof MergedUserSet).toBe(true);

	const defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_name: '',
		username: '',
		set_visible: false,
		set_params: { test_param: false },
		set_dates: { open: 0, closed: 0 }
	};
	expect(user_review_set.toObject()).toStrictEqual(defaults);
});

test('Set dates of a UserReviewSet', () => {
	const user_quiz = new MergedUserReviewSet();
	user_quiz.set_dates.open = 100;
	expect(user_quiz.set_dates.open).toBe(100);

	user_quiz.set_dates.set({
		open: 600,
		closed: 800
	});

	expect(user_quiz.set_dates.toObject()).toStrictEqual({
		open: 600,
		closed: 800
	});

	expect(user_quiz.hasValidDates()).toBe(true);

	user_quiz.set_dates.open = 1000;
	expect(user_quiz.hasValidDates()).toBe(false);

});

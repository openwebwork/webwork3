// Tests for UserSets

import { NonNegIntException } from 'src/common/models/parsers';
import { UserHomeworkSet, UserQuiz, UserReviewSet, UserSet } from 'src/common/models/user_sets';

test('Create a generic UserSet', () => {
	const user_set = new UserSet();
	expect(user_set instanceof UserSet).toBe(true);

	const user_set_defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1
	};
	// Since UserSet has 'set_params' and 'set_dates' as placeholds for subclasses,
	// don't call them in the toObject.
	// TODO: find a better way to handle this.
	const fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version'];
	expect(user_set.toObject(fields)).toStrictEqual(user_set_defaults);
});

test('Set fields of user_set directly', () => {
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

});

test('Set fields of user_set with set()', () => {
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

});

test('Create a UserHomeworkSet', () => {
	const user_hw = new UserHomeworkSet();
	expect(user_hw instanceof UserHomeworkSet).toBe(true);
	expect(user_hw instanceof UserSet).toBe(true);

	const defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_params: { enable_reduced_scoring: false },
		set_dates: { open: 0, due: 0, reduced_scoring: 0, answer: 0 }
	};
	expect(user_hw.toObject()).toStrictEqual(defaults);
});

test('Set params of a UserHomeworkSet', () => {
	const user_hw = new UserHomeworkSet();
	user_hw.set_params.enable_reduced_scoring = true;
	expect(user_hw.set_params.enable_reduced_scoring).toBe(true);

	user_hw.set_params.enable_reduced_scoring = '0';
	expect(user_hw.set_params.enable_reduced_scoring).toBe(false);

	user_hw.set_params.enable_reduced_scoring = 'true';
	expect(user_hw.set_params.enable_reduced_scoring).toBe(true);

});

test('Set dates of a UserHomeworkSet', () => {
	const user_hw = new UserHomeworkSet();
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

test('Create a UserQuiz', () => {
	const user_quiz = new UserQuiz();
	expect(user_quiz instanceof UserHomeworkSet).toBe(false);
	expect(user_quiz instanceof UserQuiz).toBe(true);
	expect(user_quiz instanceof UserSet).toBe(true);

	const defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_params: { timed: false, quiz_duration: 0 },
		set_dates: { open: 0, due: 0, answer: 0 }
	};
	expect(user_quiz.toObject()).toStrictEqual(defaults);
});

test('Set params of a UserQuiz', () => {
	const user_quiz = new UserQuiz();

	user_quiz.set_params.timed = true;
	expect(user_quiz.set_params.timed).toBe(true);

	user_quiz.set_params.timed = '0';
	expect(user_quiz.set_params.timed).toBe(false);

	user_quiz.set_params.timed = 'true';
	expect(user_quiz.set_params.timed).toBe(true);

});

test('Set dates of a UserQuiz', () => {
	const user_quiz = new UserQuiz();
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

test('Create a UserReviewSet', () => {
	const user_review_set = new UserReviewSet();
	expect(user_review_set instanceof UserHomeworkSet).toBe(false);
	expect(user_review_set instanceof UserReviewSet).toBe(true);
	expect(user_review_set instanceof UserSet).toBe(true);

	const defaults = {
		user_set_id: 0,
		set_id: 0,
		course_user_id: 0,
		set_version: 1,
		set_params: { dummy_params: false },
		set_dates: { open: 0, closed: 0 }
	};
	expect(user_review_set.toObject()).toStrictEqual(defaults);
});

test('Set dates of a UserReviewSet', () => {
	const user_quiz = new UserReviewSet();
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

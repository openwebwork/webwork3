// Tests for UserSets

import { NonNegIntException } from 'src/common/models/parsers';
import { UserHomeworkSet, UserQuiz, UserReviewSet, UserSet, ParseableUserHomeworkSet, ParseableUserQuiz }
	from 'src/common/models/user_sets';

const default_user_set = {
	user_set_id: 0,
	set_id: 0,
	course_user_id: 0,
	set_version: 1
};

test('Create a generic UserSet', () => {
	const user_set = new UserSet();
	expect(user_set instanceof UserSet).toBe(true);

	// Since UserSet has 'set_params' and 'set_dates' as placeholds for subclasses,
	// don't call them in the toObject.
	// TODO: find a better way to handle this.
	const fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version'];
	expect(user_set.toObject(fields)).toStrictEqual(default_user_set);
});

test('Check that calling all_fields() and params() is correct', () => {
	const user_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version'];
	const user_set = new UserSet();

	expect(user_set.all_field_names.sort()).toStrictEqual(user_set_fields.sort());
	expect(user_set.param_fields.sort()).toStrictEqual([]);

	expect(UserSet.ALL_FIELDS.sort()).toStrictEqual(user_set_fields.sort());

});

test('Check that cloning a Quiz works', () => {
	const user_set = new UserSet();
	expect(user_set.clone().toObject()).toStrictEqual(default_user_set);
	expect(user_set.clone() instanceof UserSet).toBe(true);
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

const default_user_homework_set: ParseableUserHomeworkSet = {
	user_set_id: 0,
	set_id: 0,
	course_user_id: 0,
	set_version: 1,
	set_params: { enable_reduced_scoring: false },
	set_dates: { open: 0, due: 0, reduced_scoring: 0, answer: 0 }
};

test('Create a UserHomeworkSet', () => {
	const user_hw = new UserHomeworkSet();
	expect(user_hw instanceof UserHomeworkSet).toBe(true);
	expect(user_hw instanceof UserSet).toBe(true);
	expect(user_hw.toObject()).toStrictEqual(default_user_homework_set);
});

test('Check that calling all_fields() and params() is correct', () => {
	const hw_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_params', 'set_dates'];
	const hw = new UserHomeworkSet();

	expect(hw.all_field_names.sort()).toStrictEqual(hw_fields.sort());
	expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

	expect(UserHomeworkSet.ALL_FIELDS.sort()).toStrictEqual(hw_fields.sort());

});

test('Check that cloning a UserHomeworkSet works', () => {
	const user_hw = new UserHomeworkSet();
	expect(user_hw.clone().toObject()).toStrictEqual(default_user_homework_set);
	expect(user_hw.clone() instanceof UserHomeworkSet).toBe(true);
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

const default_user_quiz: ParseableUserQuiz = {
	user_set_id: 0,
	set_id: 0,
	course_user_id: 0,
	set_version: 1,
	set_params: { timed: false, quiz_duration: 0 },
	set_dates: { open: 0, due: 0, answer: 0 }
};

test('Create a UserQuiz', () => {
	const user_quiz = new UserQuiz();
	expect(user_quiz instanceof UserHomeworkSet).toBe(false);
	expect(user_quiz instanceof UserQuiz).toBe(true);
	expect(user_quiz instanceof UserSet).toBe(true);
	expect(user_quiz.toObject()).toStrictEqual(default_user_quiz);
});

test('Check that calling all_fields() and params() is correct', () => {
	const quiz_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_params', 'set_dates'];
	const quiz = new UserQuiz();

	expect(quiz.all_field_names.sort()).toStrictEqual(quiz_fields.sort());
	expect(quiz.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

	expect(UserQuiz.ALL_FIELDS.sort()).toStrictEqual(quiz_fields.sort());

});

test('Check that cloning a UserHomeworkSet works', () => {
	const quiz = new UserQuiz();
	expect(quiz.clone().toObject()).toStrictEqual(default_user_quiz);
	expect(quiz.clone() instanceof UserQuiz).toBe(true);
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

const default_user_review_set = {
	user_set_id: 0,
	set_id: 0,
	course_user_id: 0,
	set_version: 1,
	set_params: { dummy_params: false },
	set_dates: { open: 0, closed: 0 }
};

test('Create a default UserReviewSet', () => {
	const user_review_set = new UserReviewSet();
	expect(user_review_set instanceof UserHomeworkSet).toBe(false);
	expect(user_review_set instanceof UserReviewSet).toBe(true);
	expect(user_review_set instanceof UserSet).toBe(true);
	expect(user_review_set.toObject()).toStrictEqual(default_user_review_set);
});

test('Check that calling all_fields() and params() is correct', () => {
	const review_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
		'set_params', 'set_dates'];
	const review = new UserReviewSet();

	expect(review.all_field_names.sort()).toStrictEqual(review_set_fields.sort());
	expect(review.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

	expect(UserReviewSet.ALL_FIELDS.sort()).toStrictEqual(review_set_fields.sort());

});

test('Check that cloning a UserReviewSet works', () => {
	const review = new UserReviewSet();
	expect(review.clone().toObject()).toStrictEqual(default_user_review_set);
	expect(review.clone() instanceof UserReviewSet).toBe(true);
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

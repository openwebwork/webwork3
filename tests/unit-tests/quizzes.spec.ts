// Tests for Quizzes

import { Quiz, ProblemSet } from 'src/common/models/problem_sets';
import { BooleanParseException, NonNegIntException } from 'src/common/models/parsers';

test('Build a Quiz', () => {
	const quiz = new Quiz();
	expect(quiz instanceof Quiz).toBe(true);
	expect(quiz instanceof ProblemSet).toBe(true);
	const quiz1 = new Quiz({ set_name: 'HW #1', set_visible: 0 });

	expect(quiz.set_visible).toBe(false);
	expect(quiz1.set_name).toBe('HW #1');

	const quiz2 = new Quiz({
		course_id:4,
		set_dates: {
			answer: 1613951940,
			due: 1612137540,
			open: 1609545540,
		},
		set_id: 7,
		set_name: 'HW #1',
		set_params: {
			timed: true,
			quiz_duration: 30
		},
		set_visible: true
	});
	const params = {
		course_id: 4,
		set_dates: {
			answer: 1613951940,
			due: 1612137540,
			open: 1609545540,
		},
		set_id: 7,
		set_name: 'HW #1',
		set_params: {
			timed: true,
			quiz_duration: 30
		},
		set_type: 'QUIZ',
		set_visible: true
	};
	expect(quiz2.toObject()).toStrictEqual(params);

});

test('Check that the quiz param defaults are working', () => {
	const quiz1 = new Quiz({ set_name: 'HW #1' });
	const quiz2 = new Quiz({ set_name: 'HW #1', set_params: { timed: false } });
	expect(quiz1).toStrictEqual(quiz2);
	const quiz3 = new Quiz({ set_name: 'HW #1', set_dates: {
		open: 0
	} });
	expect(quiz3.set_dates.open).toBe(quiz1.set_dates.open);
});

test('Test invalid Quiz params', () => {
	expect(() => { new Quiz({ set_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ set_id: '-1' });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ course_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ course_id: '-1' });}).toThrow(NonNegIntException);

	expect(() => { new Quiz({ set_visible: 'T' });}).toThrow(BooleanParseException);

});

test('Test valid Quiz params', () => {
	const quiz2 =  new Quiz();
	quiz2.set({ set_visible: 1 });
	expect(quiz2.set_visible).toBe(true);

	quiz2.set({ set_visible: false });
	expect(quiz2.set_visible).toBe(false);

	quiz2.set({ set_visible: 'true' });
	expect(quiz2.set_visible).toBe(true);

	quiz2.set({ set_name: 'HW #9' });
	expect(quiz2.set_name).toBe('HW #9');
});

test('Test the quiz dates', () => {
	const quiz = new Quiz();
	quiz.set_params.set({ timed: true });
	expect(quiz.set_params.timed).toBe(true);

	quiz.set_dates.set({
		open: 0,
		due: 10,
		answer: 20
	});
	expect(quiz.hasValidDates()).toBe(true);

	quiz.set_dates.set({
		open: 0,
		due: 30,
		answer: 20
	});
	expect(quiz.hasValidDates()).toBe(false);

	quiz.set_dates.set({
		open: 100,
		due: 20,
		answer: 150
	});
	expect(quiz.hasValidDates()).toBe(false);

	quiz.set_params.set({ timed: false });
	expect(quiz.set_params.timed).toBe(false);

	quiz.set_dates.set({
		open: 0,
		due: 10,
		answer: 15
	});
	expect(quiz.hasValidDates()).toBe(true);
});

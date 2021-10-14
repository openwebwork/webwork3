//FizzBuzz.test.ts
/// <reference types="jest" />

import { Quiz, ProblemSet } from '@/store/models/problem_sets';
import { BooleanParseException, NonNegIntException } from '@/store/models';

test('Build a Quiz', () => {
	const quiz = new Quiz();
	expect(quiz instanceof Quiz).toBe(true);
	expect(quiz instanceof ProblemSet).toBe(true);
	const quiz1 = new Quiz({ set_name: 'HW 1', set_visible: 0 });
	expect(quiz1 instanceof Quiz).toBe(true);
	expect(quiz1.set_visible).toBe(false);

});

test('Test invalid Quiz params', () => {
	expect(() => { new Quiz({ set_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ set_id: '-1' });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ course_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new Quiz({ course_id: '-1' });}).toThrow(NonNegIntException);

	expect(() => { new Quiz({ set_visible: 'T' });}).toThrow(BooleanParseException);

});

test('Test valid Quiz params', () => {
	const quiz =  new Quiz();
	quiz.set({ set_visible: 1 });
	expect(quiz.set_visible).toBe(true);

	quiz.set({ set_visible: false });
	expect(quiz.set_visible).toBe(false);

	quiz.set({ set_visible: 'true' });
	expect(quiz.set_visible).toBe(true);

	quiz.set({ set_name: 'HW #9' });
	expect(quiz.set_name).toBe('HW #9');
});

test('Test the quiz dates', () => {
	const quiz = new Quiz();
	quiz.set({ set_params: { timed: true } });
	expect(quiz.set_params.timed).toBe(true);

	quiz.set({
		set_dates: {
			open: 0,
			due: 10,
			answer: 20
		}
	});
	expect(quiz.isValid()).toBe(true);

	quiz.set({
		set_dates: {
			open: 0,
			due: 30,
			answer: 20
		}
	});
	expect(quiz.isValid()).toBe(false);

	quiz.set({
		set_dates: {
			open: 0,
			reduced_scoring: 10,
			due: 20,
			answer: 15
		}
	});
	expect(quiz.isValid()).toBe(false);
});

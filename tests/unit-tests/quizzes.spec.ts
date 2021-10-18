//FizzBuzz.test.ts
/// <reference types="jest" />

import { Quiz, ProblemSet } from '@/store/models/problem_sets';
import { BooleanParseException, InvalidFieldsException, NonNegIntException } from '@/store/models';

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
	quiz.setParams({ timed: true });
	expect(quiz.set_params.timed).toBe(true);

	quiz.setDates({
		open: 0,
		due: 10,
		answer: 20
	});
	expect(quiz.isValid()).toBe(true);

	quiz.setDates({
		open: 0,
		due: 30,
		answer: 20
	});
	expect(quiz.isValid()).toBe(false);

	quiz.setDates({
		open: 0,
		due: 20,
		answer: 15
	});
	expect(quiz.isValid()).toBe(false);
});

test('Test more quiz dates', () => {
	const quiz = new Quiz();
	quiz.setDates({
		open: '0',
		due: '20',
		answer: '30'
	});
	expect(quiz.isValid()).toBe(true);

	quiz.setDates({
		open: '0',
		due: '120',
		answer: '30'
	});
	expect(quiz.isValid()).toBe(false);

});

test('Test invalid date values', () => {
	const quiz = new Quiz();
	expect(() => {quiz.setDates({
		open: -1
	});
	}).toThrow(NonNegIntException);

	expect(() => {quiz.setDates({
		open: 'false'
	});
	}).toThrow(NonNegIntException);
});

test('Test setting invalid dates', () => {
	const quiz = new Quiz();
	expect(() => {
		quiz.setDates({
			reduced_scoring: 50
		});
	}).toThrow(InvalidFieldsException);
});

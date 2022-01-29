// Tests for Homework Sets

import { HomeworkSet, ProblemSet } from 'src/common/models/problem_sets';
import { BooleanParseException, NonNegIntException } from 'src/common/models/parsers';

test('Build a HomeworkSet', () => {
	const set = new HomeworkSet();
	expect(set instanceof HomeworkSet).toBe(true);
	expect(set instanceof ProblemSet).toBe(true);
	const set1 = new HomeworkSet({ set_name: 'HW 1', set_visible: 0 });
	expect(set1 instanceof HomeworkSet).toBe(true);
	expect(set1.set_visible).toBe(false);

	const set2 = new HomeworkSet({
		course_id:4,
		set_dates: {
			answer: 1613951940,
			due: 1612137540,
			open: 1609545540,
			reduced_scoring: 1610323140
		},
		set_id: 7,
		set_name: 'HW #1',
		set_params: {
			enable_reduced_scoring: '1'
		},
		set_visible: true
	});
	const params = {
		course_id: 4,
		set_dates: {
			answer: 1613951940,
			due: 1612137540,
			open: 1609545540,
			reduced_scoring: 1610323140
		},
		set_id: 7,
		set_name: 'HW #1',
		set_params: {
			enable_reduced_scoring: true
		},
		set_type: 'HW',
		set_visible: true
	};
	expect(set2.toObject()).toStrictEqual(params);

});

test('Check that the param defaults are working', () => {
	const set1 = new HomeworkSet({ set_name: 'HW #1' });
	const set2 = new HomeworkSet({ set_name: 'HW #1', set_params: { enable_reduced_scoring: false } });
	expect(set1).toStrictEqual(set2);
	const set3 = new HomeworkSet({ set_name: 'HW #1', set_dates: {
		open: 0
	} });
	expect(set3.set_dates.open).toBe(set1.set_dates.open);
});

test('Test invalid Homework Set params', () => {
	expect(() => { new HomeworkSet({ set_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new HomeworkSet({ set_id: '-1' });}).toThrow(NonNegIntException);
	expect(() => { new HomeworkSet({ course_id: -1 });}).toThrow(NonNegIntException);
	expect(() => { new HomeworkSet({ course_id: '-1' });}).toThrow(NonNegIntException);

	expect(() => { new HomeworkSet({ set_visible: 'T' });}).toThrow(BooleanParseException);

});

test('Test valid Homework Set params', () => {
	const set2 =  new HomeworkSet();
	set2.set({ set_visible: 1 });
	expect(set2.set_visible).toBe(true);

	set2.set({ set_visible: false });
	expect(set2.set_visible).toBe(false);

	set2.set({ set_visible: 'true' });
	expect(set2.set_visible).toBe(true);

	set2.set({ set_name: 'HW #9' });
	expect(set2.set_name).toBe('HW #9');
});

test('Test the homework set dates', () => {
	const set = new HomeworkSet();
	set.set_params.set({ enable_reduced_scoring: true });
	expect(set.set_params.enable_reduced_scoring).toBe(true);

	set.set_dates.set({
		open: 0,
		reduced_scoring: 10,
		due: 10,
		answer: 20
	});
	expect(set.hasValidDates()).toBe(true);

	set.set_dates.set({
		open: 0,
		reduced_scoring: 30,
		due: 10,
		answer: 20
	});
	expect(set.hasValidDates()).toBe(false);

	set.set_dates.set({
		open: 0,
		reduced_scoring: 10,
		due: 20,
		answer: 15
	});
	expect(set.hasValidDates()).toBe(false);

	set.set_params.set({ enable_reduced_scoring: false });
	expect(set.set_params.enable_reduced_scoring).toBe(false);

	set.set_dates.set({
		open: 0,
		reduced_scoring: 100,
		due: 10,
		answer: 15
	});
	expect(set.hasValidDates()).toBe(true);
});

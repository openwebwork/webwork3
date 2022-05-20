/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { BooleanParseException, NonNegIntException } from 'src/common/models/parsers';
import { ParseableReviewSetDates, ParseableReviewSetParams, ProblemSet,
	ReviewSet } from 'src/common/models/problem_sets';

describe('Testing for Review Sets', () => {

	const default_review_set_dates: ParseableReviewSetDates = {
		open: 0,
		closed: 0
	};

	const default_review_set_params: ParseableReviewSetParams = {
		test_param: false
	};

	const default_review_set = {
		set_dates: { ...default_review_set_dates },
		set_params: { ...default_review_set_params },
		set_id: 0,
		course_id: 0,
		set_name: '',
		set_visible: false,
		set_type: 'REVIEW'
	};

	describe('Create a new ReviewSet', () => {

		test('Test default ReviewSet', () => {
			const set = new ReviewSet();
			expect(set).toBeInstanceOf(ReviewSet);
			expect(set.toObject()).toStrictEqual(default_review_set);
		});

		test('Build a Review_set', () => {
			const review_set = new ReviewSet();
			expect(review_set).toBeInstanceOf(ReviewSet);
			expect(review_set).toBeInstanceOf(ProblemSet);
			const review_set1 = new ReviewSet({ set_name: 'Review Set #1', set_visible: 0 });

			expect(review_set.set_visible).toBeFalsy();
			expect(review_set1.set_name).toBe('Review Set #1');

			const set_params = {
				course_id:4,
				set_dates: {
					open: 1613951940,
					closed: 1609545540,
				},
				set_id: 7,
				set_name: 'Review Set #1',
				set_params: {
					test_param: true,
				},
				set_visible: true,
				set_type: 'REVIEW'
			};

			const review_set2 = new ReviewSet(set_params);
			expect(review_set2.toObject()).toStrictEqual(set_params);

		});
	});

	describe('Check the review_set Model is correct', () => {
		test('Check that calling all_fields() and params() is correct', () => {
			const review_set_fields = ['set_id', 'set_name', 'course_id', 'set_type', 'set_visible',
				'set_params', 'set_dates'];
			const review_set = new ReviewSet();

			expect(review_set.all_field_names.sort()).toStrictEqual(review_set_fields.sort());
			expect(review_set.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(ReviewSet.ALL_FIELDS.sort()).toStrictEqual(review_set_fields.sort());

		});

		test('Check that cloning a review_set works', () => {
			const review_set = new ReviewSet();
			expect(review_set.clone().toObject()).toStrictEqual(default_review_set);
			expect(review_set.clone()).toBeInstanceOf(ReviewSet);
		});
	});

	describe('Setting review_set parameters', () => {
		test('Check that the review_set param defaults are working', () => {
			const review_set1 = new ReviewSet({ set_name: 'HW #1' });
			const review_set2 = new ReviewSet({ set_name: 'HW #1', set_params: { test_param: false } });
			expect(review_set1).toStrictEqual(review_set2);
			const review_set3 = new ReviewSet({ set_name: 'HW #1', set_dates: {
				open: 0
			} });
			expect(review_set3.set_dates.open).toBe(review_set1.set_dates.open);
		});

		test('Test invalid review_set params', () => {
			expect(() => { new ReviewSet({ set_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { new ReviewSet({ set_id: '-1' });}).toThrow(NonNegIntException);
			expect(() => { new ReviewSet({ course_id: -1 });}).toThrow(NonNegIntException);
			expect(() => { new ReviewSet({ course_id: '-1' });}).toThrow(NonNegIntException);

			expect(() => { new ReviewSet({ set_visible: 'T' });}).toThrow(BooleanParseException);

		});

		test('Test valid review_set params', () => {
			const review_set2 =  new ReviewSet();
			review_set2.set({ set_visible: true });
			expect(review_set2.set_visible).toBeTruthy();

			review_set2.set({ set_visible: false });
			expect(review_set2.set_visible).toBeFalsy();

			review_set2.set({ set_name: 'HW #9' });
			expect(review_set2.set_name).toBe('HW #9');
		});
	});

	describe('Setting review_set Dates', () => {
		test('Test the review_set dates', () => {
			const review_set = new ReviewSet();
			review_set.set_params.set({ test_param: true });
			expect(review_set.set_params.test_param).toBeTruthy();

			review_set.set_dates.set({
				open: 0,
				closed: 20
			});
			expect(review_set.hasValidDates()).toBeTruthy();

			review_set.set_dates.set({
				open: 30,
				closed: 20
			});
			expect(review_set.hasValidDates()).toBeFalsy();

			review_set.set_params.set({ test_param: false });
			expect(review_set.set_params.test_param).toBeFalsy();

			review_set.set_dates.set({
				open: 0,
				closed: 15
			});

			expect(review_set.hasValidDates()).toBeTruthy();
		});
	});
});

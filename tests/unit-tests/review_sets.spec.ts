// Testing for ReviewSets.

import { ProblemSet, ReviewSet, ReviewSetDates, ReviewSetParams } from 'src/common/models/problem_sets';

describe('Testing for Review Sets', () => {

	const default_review_set = {
		set_dates: {
			open: 0,
			closed: 0
		},
		set_params: {
			test_param: false
		},
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
			expect(review_set.set_type).toBe('REVIEW');
			expect(review_set).toBeInstanceOf(ReviewSet);
			expect(review_set).toBeInstanceOf(ProblemSet);
			const review_set1 = new ReviewSet({ set_name: 'Review Set #1', set_visible: false });

			expect(review_set.set_visible).toBe(false);
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
					can_retake: true,
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

		test('Clone a ReviewSet', () => {
			const review_set = new ReviewSet();
			expect(review_set.clone().toObject()).toStrictEqual(default_review_set);
			expect(review_set.clone()).toBeInstanceOf(ReviewSet);
		});
	});

	describe('Set homework fields', () => {
		test('Check for setting fields directly', () => {
			const set = new ReviewSet();
			expect(set.set_type).toBe('REVIEW');

			set.set_id = 5;
			expect(set.set_id).toBe(5);

			set.set_name = 'review set #1';
			expect(set.set_name).toBe('review set #1');

			set.course_id = 11;
			expect(set.course_id).toBe(11);

			set.set_visible = false;
			expect(set.set_visible).toBe(false);
		});

		test('Check for setting fields using the set method', () => {
			const set = new ReviewSet();

			set.set({ set_id: 5 });
			expect(set.set_id).toBe(5);

			set.set({ set_name: 'set #1' });
			expect(set.set_name).toBe('set #1');

			set.set({ course_id: 11 });
			expect(set.course_id).toBe(11);

			set.set({ set_visible:  false });
			expect(set.set_visible).toBe(false);
		});

		test('Test the validity of a ReviewSet', () => {
			let hw = new ReviewSet();
			// A default review set is missing a set_name.
			expect(hw.isValid()).toBe(false);

			hw = new ReviewSet({ set_name: 'Review #1' });
			expect(hw.isValid()).toBe(true);

			hw = new ReviewSet({ set_name: 'Review #1', set_id: 2.34 });
			expect(hw.isValid()).toBe(false);

			hw = new ReviewSet({ set_name: 'Review #1', course_id: -32 });
			expect(hw.isValid()).toBe(false);
		});
	});

	describe('Test review_set Dates', () => {
		test('Test the review_set dates', () => {
			const review_set_dates = new ReviewSetDates();
			expect(review_set_dates.toObject()).toStrictEqual(default_review_set.set_dates);
			expect(review_set_dates.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const review_date_fields = ['open', 'closed'];
			const review_set_dates = new ReviewSetDates();

			expect(review_set_dates.all_field_names.sort()).toStrictEqual(review_date_fields.sort());
			expect(review_set_dates.param_fields).toStrictEqual([]);
			expect(ReviewSetDates.ALL_FIELDS.sort()).toStrictEqual(review_date_fields.sort());
		});

		test('Check that cloning homework set dates works', () => {
			const hw_dates = new ReviewSetDates();
			expect(hw_dates.clone().toObject()).toStrictEqual(default_review_set.set_dates);
			expect(hw_dates.clone()).toBeInstanceOf(ReviewSetDates);
		});
	});

	describe('Check setting review set dates', () => {
		test('Set review set dates directly', () => {
			const hw_dates = new ReviewSetDates();
			hw_dates.open = 100;
			expect(hw_dates.open).toBe(100);

			hw_dates.closed = 300;
			expect(hw_dates.closed).toBe(300);
		});

		test('Set homework set dates using the set method', () => {
			const hw_dates = new ReviewSetDates();
			hw_dates.set({ open: 100 });
			expect(hw_dates.open).toBe(100);

			hw_dates.set({ closed: 200 });
			expect(hw_dates.closed).toBe(200);
		});

		test('Test for valid and invalid dates', () => {
			let set_dates = new ReviewSetDates({
				open: 0,
				closed: 100
			});
			expect(set_dates.isValid()).toBe(true);

			set_dates = new ReviewSetDates({
				open: 200,
				closed: 100
			});
			expect(set_dates.isValid()).toBe(false);
		});
	});

	describe('Test setting review set params.', () => {
		test('Test the default review set params', () => {
			const review_params = new ReviewSetParams();
			expect(review_params.toObject()).toStrictEqual(default_review_set.set_params);
			expect(review_params.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const review_params_fields = ['test_param'];
			const review_params = new ReviewSetParams();

			expect(review_params.all_field_names.sort()).toStrictEqual(review_params_fields.sort());
			expect(review_params.param_fields).toStrictEqual([]);
			expect(ReviewSetParams.ALL_FIELDS.sort()).toStrictEqual(review_params_fields.sort());
		});

		test('Check that cloning homework set dates works', () => {
			const review_params = new ReviewSetParams();
			expect(review_params.clone().toObject()).toStrictEqual(default_review_set.set_params);
			expect(review_params.clone()).toBeInstanceOf(ReviewSetParams);
		});
	});

	describe('Check setting review set params', () => {
		test('Set review set params directly', () => {
			const hw_params = new ReviewSetParams();
			hw_params.test_param = true;
			expect(hw_params.test_param).toBe(true);
		});

		test('Set homework set params using the set method', () => {
			const hw_params = new ReviewSetParams();
			hw_params.set({ test_param: true });
			expect(hw_params.test_param).toBe(true);
		});

		// No tests for validity for this currently because there is nothing
		// check.  If the ReviewSetParams are updated to include checking for validity
		// then another test should be included.
	});
});

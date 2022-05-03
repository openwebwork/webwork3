/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { DBUserHomeworkSet, DBUserReviewSet, DBUserSet, UserHomeworkSet, UserReviewSet, UserSet } from 'src/common/models/user_sets';

describe('Testing db user Review Sets and User Review Sets', () => {

	describe('Create a database User Review Set', () => {
		const default_user_review_set = {
			user_set_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_visible: false,
			set_type: 'REVIEW',
			set_params: { test_param: false },
			set_dates: {}
		};

		test('Create a default UserReviewSet', () => {
			const user_review_set = new DBUserReviewSet();
			expect(user_review_set).not.toBeInstanceOf(DBUserHomeworkSet);
			expect(user_review_set).toBeInstanceOf(DBUserReviewSet);
			expect(user_review_set).toBeInstanceOf(DBUserSet);
			expect(user_review_set.toObject()).toStrictEqual(default_user_review_set);
		});

		test('Check that calling all_fields() and params() is correct for a review set', () => {
			const review_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'set_visible', 'set_params', 'set_dates', 'set_type'];
			const review = new DBUserReviewSet();

			expect(review.all_field_names.sort()).toStrictEqual(review_set_fields.sort());
			expect(review.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(DBUserReviewSet.ALL_FIELDS.sort()).toStrictEqual(review_set_fields.sort());

		});

		test('Check that cloning a database UserReviewSet works', () => {
			const review = new DBUserReviewSet();
			expect(review.clone().toObject()).toStrictEqual(default_user_review_set);
			expect(review.clone()).toBeInstanceOf(DBUserReviewSet);
		});
	});

	describe('Update a db User Review Set', () => {
		test('Set dates of a DBUserReviewSet', () => {
			const user_quiz = new DBUserReviewSet();
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

			expect(user_quiz.hasValidDates()).toBeTruthy();

			user_quiz.set_dates.open = 1000;
			expect(user_quiz.hasValidDates()).toBeFalsy();

		});

		describe('Creating user review sets', () => {
			test('Create a UserReviewSet', () => {
				const user_review_set = new UserReviewSet();
				expect(user_review_set).not.toBeInstanceOf(UserHomeworkSet);
				expect(user_review_set).toBeInstanceOf(UserReviewSet);
				expect(user_review_set).toBeInstanceOf(UserSet);

				const defaults = {
					user_set_id: 0,
					user_id: 0,
					set_id: 0,
					course_user_id: 0,
					set_version: 1,
					set_name: '',
					username: '',
					set_params: { test_param: false },
					set_dates: { open: 0, closed: 0 }
				};
				expect(user_review_set.toObject()).toStrictEqual(defaults);
			});
		});

		describe('Updating a user review set', () => {
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

				expect(user_quiz.hasValidDates()).toBeTruthy();

				user_quiz.set_dates.open = 1000;
				expect(user_quiz.hasValidDates()).toBeFalsy();

			});
		});
	});
});

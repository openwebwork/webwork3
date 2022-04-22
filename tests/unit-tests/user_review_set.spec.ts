/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { MergedUserHomeworkSet, MergedUserReviewSet, MergedUserSet, UserHomeworkSet,
	UserReviewSet, UserSet } from 'src/common/models/user_sets';

describe('Testing user Review Sets and Merged Review Sets', () => {

	describe('Create a User Review Set', () => {
		const default_user_review_set = {
			user_set_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_params: { test_param: false },
			set_dates: { open: 0, closed: 0 }
		};

		test('Create a default UserReviewSet', () => {
			const user_review_set = new UserReviewSet();
			expect(user_review_set instanceof UserHomeworkSet).toBeFalsy();
			expect(user_review_set).toBeInstanceOf(UserReviewSet);
			expect(user_review_set).toBeInstanceOf(UserSet);
			expect(user_review_set.toObject()).toStrictEqual(default_user_review_set);
		});

		test('Check that calling all_fields() and params() is correct for a review set', () => {
			const review_set_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'set_visible', 'set_params', 'set_dates'];
			const review = new UserReviewSet();

			expect(review.all_field_names.sort()).toStrictEqual(review_set_fields.sort());
			expect(review.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(UserReviewSet.ALL_FIELDS.sort()).toStrictEqual(review_set_fields.sort());

		});

		test('Check that cloning a UserReviewSet works', () => {
			const review = new UserReviewSet();
			expect(review.clone().toObject()).toStrictEqual(default_user_review_set);
			expect(review.clone() instanceof UserReviewSet).toBeTruthy();
		});
	});

	describe('Update a User Review Set', () => {
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

		describe('Creating merged user review sets', () => {
			test('Create a MergedUserReviewSet', () => {
				const user_review_set = new MergedUserReviewSet();
				expect(user_review_set instanceof MergedUserHomeworkSet).toBeFalsy();
				expect(user_review_set).toBeInstanceOf(MergedUserReviewSet);
				expect(user_review_set).toBeInstanceOf(MergedUserSet);

				const defaults = {
					user_set_id: 0,
					user_id: 0,
					set_id: 0,
					course_user_id: 0,
					set_version: 1,
					set_name: '',
					username: '',
					set_params: { test_param: false },
					set_dates: {}
				};
				expect(user_review_set.toObject()).toStrictEqual(defaults);
			});
		});

		describe('Updating a user review set', () => {
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

				expect(user_quiz.hasValidDates()).toBeTruthy();

				user_quiz.set_dates.open = 1000;
				expect(user_quiz.hasValidDates()).toBeFalsy();

			});
		});
	});
});

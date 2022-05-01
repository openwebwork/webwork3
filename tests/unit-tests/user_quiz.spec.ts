/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { Quiz } from 'src/common/models/problem_sets';
import { MergedUser } from 'src/common/models/users';
import { MergedUserHomeworkSet, MergedUserQuiz, MergedUserSet, mergeUserSet, ParseableUserQuiz,
	UserHomeworkSet, UserQuiz, UserSet } from 'src/common/models/user_sets';

describe('Test User Quizzes', () => {
	describe('Create User Quizzes', () => {
		const default_user_quiz: ParseableUserQuiz = {
			user_set_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_visible: false,
			set_type: 'QUIZ',
			set_params: { timed: false, quiz_duration: 0 },
			set_dates: {}
		};

		test('Create a UserQuiz', () => {
			const user_quiz = new UserQuiz();
			expect(user_quiz).not.toBeInstanceOf(UserHomeworkSet);
			expect(user_quiz).toBeInstanceOf(UserQuiz);
			expect(user_quiz).toBeInstanceOf(UserSet);
			expect(user_quiz.toObject()).toStrictEqual(default_user_quiz);
		});

		test('Check that calling all_fields() and params() is correct for a quiz', () => {
			const quiz_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'set_type', 'set_visible', 'set_params', 'set_dates'];
			const quiz = new UserQuiz();

			expect(quiz.all_field_names.sort()).toStrictEqual(quiz_fields.sort());
			expect(quiz.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(UserQuiz.ALL_FIELDS.sort()).toStrictEqual(quiz_fields.sort());

		});

		test('Check that cloning a UserHomeworkSet works', () => {
			const quiz = new UserQuiz();
			expect(quiz.clone().toObject()).toStrictEqual(default_user_quiz);
			expect(quiz.clone() instanceof UserQuiz).toBeTruthy();
		});
	});

	describe('Update a User Quiz', () => {
		test('Set params of a UserQuiz', () => {
			const user_quiz = new UserQuiz();

			user_quiz.set_params.timed = true;
			expect(user_quiz.set_params.timed).toBeTruthy();

			user_quiz.set_params.timed = '0';
			expect(user_quiz.set_params.timed).toBeFalsy();

			user_quiz.set_params.timed = 'true';
			expect(user_quiz.set_params.timed).toBeTruthy();

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

			expect(user_quiz.hasValidDates()).toBeTruthy();

			user_quiz.set_dates.due = 1000;
			expect(user_quiz.hasValidDates()).toBeFalsy();

		});
	});

	describe('Create Merged User quizzes', () => {

		const default_merged_quiz_params = {
			user_set_id: 0,
			user_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_name: '',
			username: '',
			set_type: 'QUIZ',
			set_params: { timed: false, quiz_duration: 0 },
			set_dates: { open:0, due: 0, answer: 0 }
		};


		test('Create a MergedUserQuiz', () => {
			const user_quiz = new MergedUserQuiz();
			expect(user_quiz).not.toBeInstanceOf(MergedUserHomeworkSet);
			expect(user_quiz).toBeInstanceOf(MergedUserQuiz);
			expect(user_quiz).toBeInstanceOf(MergedUserSet);

			expect(user_quiz.toObject()).toStrictEqual(default_merged_quiz_params);
		});


		test('Check that calling all_fields() and params() is correct', () => {
			const merged_user_quiz_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'user_id', 'set_visible', 'set_name', 'set_type', 'username', 'set_params', 'set_dates'];
			const hw = new MergedUserHomeworkSet();

			expect(hw.all_field_names.sort()).toStrictEqual(merged_user_quiz_fields.sort());
			expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(MergedUserHomeworkSet.ALL_FIELDS.sort()).toStrictEqual(merged_user_quiz_fields.sort());

		});

		test('Check that cloning a MergedUserHomeworkSet works', () => {
			const quiz = new MergedUserQuiz();
			expect(quiz.clone().toObject()).toStrictEqual(default_merged_quiz_params);
			expect(quiz.clone()).toBeInstanceOf(MergedUserQuiz);
		});
	});


	describe('Update Merged user quizzes', () => {
		test('Set params of a MergedUserQuiz', () => {
			const user_quiz = new MergedUserQuiz();

			user_quiz.set_params.timed = true;
			expect(user_quiz.set_params.timed).toBeTruthy();

			user_quiz.set_params.timed = '0';
			expect(user_quiz.set_params.timed).toBeFalsy();

			user_quiz.set_params.timed = 'true';
			expect(user_quiz.set_params.timed).toBeTruthy();

		});

		test('Set dates of a MergedUserQuiz', () => {
			const user_quiz = new MergedUserQuiz();
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

			expect(user_quiz.hasValidDates()).toBeTruthy();

			user_quiz.set_dates.due = 1000;
			expect(user_quiz.hasValidDates()).toBeFalsy();

		});
	});

	describe('Merging a Quiz, user quiz and user', () => {
		const user = new MergedUser({
			user_id: 99,
			course_user_id: 299,
			username: 'homer',
			first_name: 'Homer',
			last_name: 'Simpson',
			email: 'homer@msn.com'
		});
		const hw = new Quiz({
			set_name: 'Quiz #1',
			set_id: 99,
			set_dates: {
				open: 100,
				due: 200,
				answer: 300
			}
		});
		const user_set = new UserQuiz({
			set_id: 99,
			course_user_id: 299
		});

		test('created a merged user quiz with empty user set dates', () => {
			const expected_user_hw = new MergedUserQuiz({
				user_id: 99,
				course_user_id: 299,
				username: 'homer',
				set_name: 'Quiz #1',
				set_visible: false,
				set_id: 99,
				set_dates: {
					open: 100,
					due: 200,
					answer: 300
				}
			});
			const merged_set = mergeUserSet(hw, user_set, user);
			expect(expected_user_hw).toStrictEqual(merged_set);
		});

		test('create a merged user homework set with complete set of user set dates', () => {
			user_set.set_dates.set({
				open: 150,
				answer: 500
			});
			const expected_user_quiz = new MergedUserQuiz({
				user_id: 99,
				course_user_id: 299,
				username: 'homer',
				set_name: 'Quiz #1',
				set_visible: false,
				set_id: 99,
				set_dates: {
					open: 150,
					due: 200,
					answer: 500
				}
			});
			const merged_set = mergeUserSet(hw, user_set, user);
			expect(expected_user_quiz).toStrictEqual(merged_set);
		});
	});
});

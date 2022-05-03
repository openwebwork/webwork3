/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { Quiz } from 'src/common/models/problem_sets';
import { CourseUser } from 'src/common/models/users';
import { DBUserHomeworkSet, DBUserQuiz, DBUserSet, mergeUserSet, ParseableDBUserQuiz,
	UserHomeworkSet, UserQuiz, UserSet } from 'src/common/models/user_sets';

describe('Test User Quizzes', () => {
	describe('Create database User Quizzes', () => {
		const default_user_quiz: ParseableDBUserQuiz = {
			user_set_id: 0,
			set_id: 0,
			course_user_id: 0,
			set_version: 1,
			set_visible: false,
			set_type: 'QUIZ',
			set_params: { timed: false, quiz_duration: 0 },
			set_dates: {}
		};

		test('Create a DBUserQuiz', () => {
			const user_quiz = new DBUserQuiz();
			expect(user_quiz).not.toBeInstanceOf(DBUserHomeworkSet);
			expect(user_quiz).toBeInstanceOf(DBUserQuiz);
			expect(user_quiz).toBeInstanceOf(DBUserSet);
			expect(user_quiz.toObject()).toStrictEqual(default_user_quiz);
		});

		test('Check that calling all_fields() and params() is correct for a db user quiz', () => {
			const quiz_fields = ['user_set_id', 'set_id', 'course_user_id', 'set_version',
				'set_visible', 'set_params', 'set_dates', 'set_type'];
			const quiz = new DBUserQuiz();

			expect(quiz.all_field_names.sort()).toStrictEqual(quiz_fields.sort());
			expect(quiz.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);

			expect(DBUserQuiz.ALL_FIELDS.sort()).toStrictEqual(quiz_fields.sort());

		});

		test('Check that cloning a DBUserQuiz works', () => {
			const quiz = new DBUserQuiz();
			expect(quiz.clone().toObject()).toStrictEqual(default_user_quiz);
			expect(quiz.clone()).toBeInstanceOf(DBUserQuiz);
		});
	});

	describe('Update a DBUserQuiz', () => {
		test('Set params of a DBUserQuiz', () => {
			const user_quiz = new DBUserQuiz();

			user_quiz.set_params.timed = true;
			expect(user_quiz.set_params.timed).toBeTruthy();

			user_quiz.set_params.timed = '0';
			expect(user_quiz.set_params.timed).toBeFalsy();

			user_quiz.set_params.timed = 'true';
			expect(user_quiz.set_params.timed).toBeTruthy();

		});

		test('Set dates of a UserQuiz', () => {
			const user_quiz = new DBUserQuiz();
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

	describe('Create User quizzes', () => {
		test('Create a UserQuiz', () => {
			const user_quiz = new UserQuiz();
			expect(user_quiz instanceof UserHomeworkSet).toBeFalsy();
			expect(user_quiz).toBeInstanceOf(UserQuiz);
			expect(user_quiz).toBeInstanceOf(UserSet);

			const defaults = {
				user_set_id: 0,
				user_id: 0,
				set_id: 0,
				course_user_id: 0,
				set_version: 1,
				set_name: '',
				username: '',
				set_params: { timed: false, quiz_duration: 0 },
				set_dates: { open:0, due: 0, answer: 0 }
			};
			expect(user_quiz.toObject()).toStrictEqual(defaults);
		});
	});

	describe('Update user quizzes', () => {
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

	describe('Merging a Quiz, user quiz and user', () => {
		const user = new CourseUser({
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
		const db_user_set = new DBUserQuiz({
			set_id: 99,
			course_user_id: 299
		});

		test('created a user quiz with empty user set dates', () => {
			const expected_user_hw = new UserQuiz({
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
			const user_set = mergeUserSet(hw, db_user_set, user);
			expect(expected_user_hw).toStrictEqual(user_set);
		});

		test('create a user homework set with complete set of user set dates', () => {
			db_user_set.set_dates.set({
				open: 150,
				answer: 500
			});
			const expected_user_quiz = new UserQuiz({
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
			const user_set = mergeUserSet(hw, db_user_set, user);
			expect(expected_user_quiz).toStrictEqual(user_set);
		});
	});
});

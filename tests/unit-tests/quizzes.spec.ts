// Tests for Quizzes

import { Quiz, ProblemSet, QuizDates, QuizParams } from 'src/common/models/problem_sets';

describe('Testing for Quizzes', () => {
	const default_quiz = {
		set_dates: {
			answer: 0,
			due: 0,
			open: 0
		},
		set_params: {
			timed: false,
			quiz_duration: 0
		},
		set_id: 0,
		course_id: 0,
		set_name: '',
		set_visible: false,
		set_type: 'QUIZ'
	};

	describe('Create a new Quiz', () => {

		test('Test default Quiz', () => {
			const set = new Quiz();
			expect(set).toBeInstanceOf(Quiz);
			expect(set.toObject()).toStrictEqual(default_quiz);
		});

		test('Build a Quiz', () => {
			const quiz = new Quiz();
			expect(quiz).toBeInstanceOf(Quiz);
			expect(quiz).toBeInstanceOf(ProblemSet);
			const quiz1 = new Quiz({ set_name: 'HW #1', set_visible: false });

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
	});

	describe('Check the Quiz Model is correct', () => {
		test('Check that calling all_fields() and params() is correct', () => {
			const quiz_fields = ['set_id', 'set_name', 'course_id', 'set_type', 'set_visible',
				'set_params', 'set_dates'];
			const quiz = new Quiz();

			expect(quiz.all_field_names.sort()).toStrictEqual(quiz_fields.sort());
			expect(quiz.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);
			expect(Quiz.ALL_FIELDS.sort()).toStrictEqual(quiz_fields.sort());
		});

		test('Check that cloning a Quiz works', () => {
			const quiz = new Quiz();
			expect(quiz.clone().toObject()).toStrictEqual(default_quiz);
			expect(quiz.clone()).toBeInstanceOf(Quiz);
		});
	});

	describe('Setting the quiz fields', () => {
		test('Check for setting fields directly', () => {
			const quiz = new Quiz();
			expect(quiz.set_type).toBe('QUIZ');

			quiz.set_id = 5;
			expect(quiz.set_id).toBe(5);

			quiz.set_name = 'Quiz #1';
			expect(quiz.set_name).toBe('Quiz #1');

			quiz.course_id = 11;
			expect(quiz.course_id).toBe(11);

			quiz.set_visible = false;
			expect(quiz.set_visible).toBe(false);
		});

		test('Check for setting fields using the set method', () => {
			const quiz = new Quiz();

			quiz.set({ set_id: 5 });
			expect(quiz.set_id).toBe(5);

			quiz.set({ set_name: 'Quiz #1' });
			expect(quiz.set_name).toBe('Quiz #1');

			quiz.set({ course_id: 11 });
			expect(quiz.course_id).toBe(11);

			quiz.set({ set_visible:  false });
			expect(quiz.set_visible).toBe(false);
		});
	});

	describe('Creating a Quiz Date', () => {
		test('Test the default quiz dates', () => {
			const quiz_dates = new QuizDates();
			expect(quiz_dates.toObject()).toStrictEqual(default_quiz.set_dates);
			expect(quiz_dates.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const quiz_date_fields = ['open', 'due', 'answer'];
			const quiz_dates = new QuizDates();

			expect(quiz_dates.all_field_names.sort()).toStrictEqual(quiz_date_fields.sort());
			expect(quiz_dates.param_fields).toStrictEqual([]);
			expect(QuizDates.ALL_FIELDS.sort()).toStrictEqual(quiz_date_fields.sort());
		});

		test('Check that cloning quiz dates works', () => {
			const quiz_dates = new QuizDates();
			expect(quiz_dates.clone().toObject()).toStrictEqual(default_quiz.set_dates);
			expect(quiz_dates.clone()).toBeInstanceOf(QuizDates);
		});
	});

	describe('Check setting quiz dates', () => {
		test('Set quiz dates directly', () => {
			const quiz_dates = new QuizDates();
			quiz_dates.open = 100;
			expect(quiz_dates.open).toBe(100);

			quiz_dates.due = 300;
			expect(quiz_dates.due).toBe(300);

			quiz_dates.answer = 400;
			expect(quiz_dates.answer).toBe(400);

		});

		test('Set quiz dates using the set method', () => {
			const quiz_dates = new QuizDates();
			quiz_dates.set({ open: 100 });
			expect(quiz_dates.open).toBe(100);

			quiz_dates.set({ due: 300 });
			expect(quiz_dates.due).toBe(300);

			quiz_dates.set({ answer: 400 });
			expect(quiz_dates.answer).toBe(400);
		});

		test('Test for valid and invalid dates', () => {
			const quiz_dates = new QuizDates();
			quiz_dates.set({
				open: 0,
				due: 10,
				answer: 20
			});
			expect(quiz_dates.isValid()).toBe(true);

			quiz_dates.set({
				open: 30,
				due: 10,
				answer: 20
			});
			expect(quiz_dates.isValid()).toBe(false);

			quiz_dates.set({
				open: 0,
				due: 30,
				answer: 20
			});
			expect(quiz_dates.isValid()).toBe(false);
		});
	});

	describe('Test setting quiz params.', () => {
		test('Test the default quiz params', () => {
			const quiz_params = new QuizParams();
			expect(quiz_params.toObject()).toStrictEqual(default_quiz.set_params);
			expect(quiz_params.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const quiz_params_fields = ['timed', 'quiz_duration'];
			const quiz_params = new QuizParams();

			expect(quiz_params.all_field_names.sort()).toStrictEqual(quiz_params_fields.sort());
			expect(quiz_params.param_fields).toStrictEqual([]);
			expect(QuizParams.ALL_FIELDS.sort()).toStrictEqual(quiz_params_fields.sort());
		});

		test('Check that cloning quiz dates works', () => {
			const quiz_params = new QuizParams();
			expect(quiz_params.clone().toObject()).toStrictEqual(default_quiz.set_params);
			expect(quiz_params.clone()).toBeInstanceOf(QuizParams);
		});
	});

	describe('Check setting quiz params', () => {
		test('Set quiz params directly', () => {
			const quiz_params = new QuizParams();
			quiz_params.timed = true;
			expect(quiz_params.timed).toBe(true);

			quiz_params.quiz_duration = 30;
			expect(quiz_params.quiz_duration).toBe(30);
		});

		test('Set quiz params using the set method', () => {
			const quiz_params = new QuizParams();
			quiz_params.set({ timed: true });
			expect(quiz_params.timed).toBe(true);

			quiz_params.set({ quiz_duration: 30 });
			expect(quiz_params.quiz_duration).toBe(30);
		});

	});

	describe('Check the Validity of the Quiz Params', () => {
		test('Check valid and invalid params', () => {
			const quiz_params = new QuizParams({ timed: true, quiz_duration: 30 });
			expect(quiz_params.isValid()).toBe(true);

			quiz_params.set({ quiz_duration: 30.5 });
			expect(quiz_params.isValid()).toBe(false);
		});
	});
});

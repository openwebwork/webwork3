// Testing UserProblems

import { NonNegDecimalException, NonNegIntException } from 'src/common/models/parsers';
import { ProblemType, UserProblem } from 'src/common/models/problems';

describe('Testing User Problems', () => {

	const default_render_params = {
		problemSeed: 1234,
		permissionLevel: 0,
		outputFormat: 'ww3',
		answerPrefix: '',
		sourceFilePath: '',
		showHints: false,
		showSolutions: false,
		showPreviewButton: true,
		showCheckAnswersButton: true,
		showCorrectAnswersButton: false
	};

	const default_user_problem = {
		render_params: { ...default_render_params },
		problem_params: {},
		user_problem_id: 0,
		problem_id: 0,
		user_set_id: 0,
		seed: 0,
		status: 0,
		problem_version: 1
	};

	describe('Creating generic User Problems', () => {
		test('Create a Generic default User Problem', () => {
			const user_problem = new UserProblem();
			expect(user_problem).toBeInstanceOf(UserProblem);
			expect(user_problem.problem_type).toBe(ProblemType.USER);
			expect(user_problem.toObject()).toStrictEqual(default_user_problem);

		});

		test('Check that calling all_fields() and params() is correct', () => {
			const prob = new UserProblem();
			const user_problem_fields = ['render_params', 'problem_params', 'user_problem_id',
				'problem_id', 'user_set_id', 'seed', 'status', 'problem_version'];

			expect(prob.all_field_names.sort()).toStrictEqual(user_problem_fields.sort());
			expect(prob.param_fields.sort()).toStrictEqual(['problem_params', 'render_params']);

			expect(UserProblem.ALL_FIELDS.sort()).toStrictEqual(user_problem_fields.sort());

		});

		test('Check that cloning a user problem works', () => {
			const prob = new UserProblem();
			expect(prob.clone().toObject()).toStrictEqual(default_user_problem);
			expect(prob.clone() instanceof UserProblem).toBe(true);
		});
	});

	describe('Updating Generic User Problems', () => {

		test('Check the changing problem params directly works', () => {
			const prob = new UserProblem();
			prob.problem_params.weight = 2;
			expect(prob.problem_params.weight).toBe(2);
			prob.problem_params.weight = '3.5';
			expect(prob.problem_params.weight).toBe(3.5);

			prob.problem_params.library_id = 10;
			expect(prob.problem_params.library_id).toBe(10);
			prob.problem_params.library_id = '12';
			expect(prob.problem_params.library_id).toBe(12);

			prob.problem_params.file_path = 'path/to/file';
			expect(prob.problem_params.file_path).toBe('path/to/file');

			prob.problem_params.problem_pool_id = 15;
			expect(prob.problem_params.problem_pool_id).toBe(15);
			prob.problem_params.problem_pool_id = '25';
			expect(prob.problem_params.problem_pool_id).toBe(25);

		});

		test('Check the changing problem params using set() works', () => {
			const prob = new UserProblem();
			prob.problem_params.set({ weight: 2 });
			expect(prob.problem_params.weight).toBe(2);
			prob.problem_params.set({ weight: '3.5' });
			expect(prob.problem_params.weight).toBe(3.5);

			prob.problem_params.set({ library_id: 10 });
			expect(prob.problem_params.library_id).toBe(10);
			prob.problem_params.set({ library_id: '12' });
			expect(prob.problem_params.library_id).toBe(12);

			prob.problem_params.set({ file_path: 'path/to/file' });
			expect(prob.problem_params.file_path).toBe('path/to/file');

			prob.problem_params.set({ problem_pool_id: 15 });
			expect(prob.problem_params.problem_pool_id).toBe(15);
			prob.problem_params.set({ problem_pool_id: '25' });
			expect(prob.problem_params.problem_pool_id).toBe(25);

		});

		test('Check changes in fields set directly', () => {
			const prob = new UserProblem();
			prob.problem_id = 5;
			expect(prob.problem_id).toBe(5);
			prob.problem_id = '7';
			expect(prob.problem_id).toBe(7);

			prob.user_problem_id = 15;
			expect(prob.user_problem_id).toBe(15);
			prob.user_problem_id = '27';
			expect(prob.user_problem_id).toBe(27);

			prob.user_set_id = 8;
			expect(prob.user_set_id).toBe(8);
			prob.user_set_id = '34';
			expect(prob.user_set_id).toBe(34);

			prob.seed = 12345;
			expect(prob.seed).toBe(12345);
			prob.seed = '7654';
			expect(prob.seed).toBe(7654);

			prob.status = 2;
			expect(prob.status).toBe(2);
			prob.status = '2.5';
			expect(prob.status).toBe(2.5);

			prob.problem_version = 3;
			expect(prob.problem_version).toBe(3);
			prob.problem_version = '4';
			expect(prob.problem_version).toBe(4);

		});

		test('Check changes in fields using set()', () => {
			const prob = new UserProblem();
			prob.set({ problem_id: 5 });
			expect(prob.problem_id).toBe(5);
			prob.set({ problem_id: '7' });
			expect(prob.problem_id).toBe(7);

			prob.set({ user_problem_id: 15 });
			expect(prob.user_problem_id).toBe(15);
			prob.set({ user_problem_id: '27' });
			expect(prob.user_problem_id).toBe(27);

			prob.set({ user_set_id: 8 });
			expect(prob.user_set_id).toBe(8);
			prob.set({ user_set_id: '34' });
			expect(prob.user_set_id).toBe(34);

			prob.set({ seed: 12345 });
			expect(prob.seed).toBe(12345);
			prob.set({ seed: '7654' });
			expect(prob.seed).toBe(7654);

			prob.set({ status: 2 });
			expect(prob.status).toBe(2);
			prob.set({ status: '2.5' });
			expect(prob.status).toBe(2.5);

			prob.set({ problem_version: 3 });
			expect(prob.problem_version).toBe(3);
			prob.set({ problem_version: '4' });
			expect(prob.problem_version).toBe(4);

		});

		test('Check that exceptions are thrown for invalid direct settings', () => {
			const prob = new UserProblem();
			expect(() => {prob.problem_id = -1; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_id = '-5'; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_id = 1.5; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_id = '4.3'; }).toThrow(NonNegIntException);

			expect(() => {prob.user_set_id = -1; }).toThrow(NonNegIntException);
			expect(() => {prob.user_set_id = '-5'; }).toThrow(NonNegIntException);
			expect(() => {prob.user_set_id = 1.5; }).toThrow(NonNegIntException);
			expect(() => {prob.user_set_id = '4.3'; }).toThrow(NonNegIntException);

			expect(() => {prob.user_problem_id = -10; }).toThrow(NonNegIntException);
			expect(() => {prob.user_problem_id = '-15'; }).toThrow(NonNegIntException);
			expect(() => {prob.user_problem_id = 2.5; }).toThrow(NonNegIntException);
			expect(() => {prob.user_problem_id = '7.4'; }).toThrow(NonNegIntException);

			expect(() => {prob.seed = -5; }).toThrow(NonNegIntException);
			expect(() => {prob.seed = '-3'; }).toThrow(NonNegIntException);
			expect(() => {prob.seed = 1.25; }).toThrow(NonNegIntException);
			expect(() => {prob.seed = '17.3'; }).toThrow(NonNegIntException);

			expect(() => {prob.status = -1; }).toThrow(NonNegDecimalException);
			expect(() => {prob.status = '-5'; }).toThrow(NonNegDecimalException);

			expect(() => {prob.problem_version = -21; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_version = '-35'; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_version = 1.65; }).toThrow(NonNegIntException);
			expect(() => {prob.problem_version = '4.33'; }).toThrow(NonNegIntException);

		});

		test('Check that exceptions are thrown for invalid field using set()', () => {
			const prob = new UserProblem();
			expect(() => {prob.set({ problem_id: -1 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_id: '-5' }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_id: 1.5 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_id: '4.3' }); }).toThrow(NonNegIntException);

			expect(() => {prob.set({ user_set_id: -1 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_set_id: '-5' }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_set_id: 1.5 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_set_id: '4.3' }); }).toThrow(NonNegIntException);

			expect(() => {prob.set({ user_problem_id: -10 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_problem_id: '-15' }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_problem_id: 2.5 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ user_problem_id: '7.4' }); }).toThrow(NonNegIntException);

			expect(() => {prob.set({ seed: -5 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ seed: '-3' }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ seed: 1.25 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ seed: '17.3' }); }).toThrow(NonNegIntException);

			expect(() => {prob.set({ status: -1 }); }).toThrow(NonNegDecimalException);
			expect(() => {prob.set({ status: '-5' }); }).toThrow(NonNegDecimalException);

			expect(() => {prob.set({ problem_version: -21 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_version: '-35' }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_version: 1.65 }); }).toThrow(NonNegIntException);
			expect(() => {prob.set({ problem_version: '4.33' }); }).toThrow(NonNegIntException);
		});
	});
});

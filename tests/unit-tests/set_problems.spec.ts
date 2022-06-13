import { ParseableSetProblem, ParseableSetProblemParams, ProblemType, SetProblem } from 'src/common/models/problems';

describe('Test the SetProblems', () => {

	const default_render_params = {
		problemSeed: 1234,
		permissionLevel: 0,
		outputFormat: 'ww3',
		answerPrefix: 'SET0_',
		sourceFilePath: '',
		showHints: false,
		showSolutions: true,
		showPreviewButton: true,
		showCheckAnswersButton: true,
		showCorrectAnswersButton: true
	};

	const default_problem_params: ParseableSetProblemParams = {
		weight: 1,
	};

	const default_problem_set: ParseableSetProblem = {
		set_problem_id: 0,
		set_id: 0,
		problem_number: 0,
		render_params: { ... default_render_params },
		problem_params: { ... default_problem_params }
	};

	describe('Creating a Set Problem', () => {
		test('Test creation of a Set Problem', () => {
			const prob = new SetProblem();
			expect(prob instanceof SetProblem).toBe(true);

			// remove the problem_type from the toObject, since we can't set it.
			const p = prob.toObject();
			delete p.problem_type;

			expect(p).toStrictEqual(default_problem_set);
			expect(prob.problem_type).toBe(ProblemType.SET);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const set_problem_fields = ['render_params', 'problem_params', 'problem_id',
				'set_id', 'problem_number'];
			const prob = new SetProblem();

			expect(prob.all_field_names.sort()).toStrictEqual(set_problem_fields.sort());
			expect(prob.param_fields.sort()).toStrictEqual(['problem_params', 'render_params']);

			expect(SetProblem.ALL_FIELDS.sort()).toStrictEqual(set_problem_fields.sort());
		});

		test('Clone a Set problem', () => {
			const prob = new SetProblem();
			expect(prob.clone().toObject()).toStrictEqual(default_problem_set);
			expect(prob.clone() instanceof SetProblem).toBe(true);
		});
	});

	describe('Checking rendering params', () => {
		test('Check that default rendering parameters are set.', () => {
			const prob = new SetProblem();
			expect(prob.render_params.toObject()).toStrictEqual(default_render_params);
		});

		test('Check that changing the render params works', () => {
			const prob = new SetProblem();
			prob.setRenderParams({ problemSeed: 1234 });
			expect(prob.render_params.problemSeed).toBe(1234);
		});
	});

	describe('Set Problem fields', () => {
		test('Check setting set problem fields directly', () => {
			const prob = new SetProblem();
			prob.problem_number = 9;
			expect(prob.problem_number).toBe(9);

			prob.problem_id = 9;
			expect(prob.problem_id).toBe(9);

			prob.set_id = 5;
			expect(prob.set_id).toBe(5);
		});

		test('Check setting set problem fields using set()', () => {
			const prob = new SetProblem();
			prob.set({ problem_number: 9 });
			expect(prob.problem_number).toBe(9);

			prob.set({ problem_id: 9 });
			expect(prob.problem_id).toBe(9);

			prob.set({ set_id: 5 });
			expect(prob.set_id).toBe(5);
		});

		test('Check for invalid SetProblems', () => {
			const prob = new SetProblem({ problem_params: { file_path: '/this/is/the/path' } });
			expect(prob.isValid()).toBe(true);

			prob.problem_number = -1;
			expect(prob.isValid()).toBe(false);
			prob.problem_number = 1.234;
			expect(prob.isValid()).toBe(false);

			prob.problem_id = -1;
			expect(prob.isValid()).toBe(false);
			prob.problem_id = 3.14;
			expect(prob.isValid()).toBe(false);

			prob.set_id = -5;
			expect(prob.isValid()).toBe(false);
			prob.set_id = 2.34;
			expect(prob.isValid()).toBe(false);
		});
	});

	describe('Checking problem location params', () => {
		test('Setting problem params directly', () => {
			const prob = new SetProblem();

			prob.problem_params.weight = 1.5;
			expect(prob.problem_params.weight).toBe(1.5);

			prob.problem_params.library_id = 1234;
			expect(prob.problem_params.library_id).toBe(1234);

			prob.problem_params.file_path = 'this_is_the_path';
			expect(prob.problem_params.file_path).toBe('this_is_the_path');

			prob.problem_params.problem_pool_id = 12;
			expect(prob.problem_params.problem_pool_id).toBe(12);
		});

		test('Setting problem params using set()', () => {
			const prob = new SetProblem();

			prob.problem_params.set({ weight: 1.5 });
			expect(prob.problem_params.weight).toBe(1.5);

			prob.problem_params.set({ library_id: 1234 });
			expect(prob.problem_params.library_id).toBe(1234);

			prob.problem_params.set({ file_path: 'this_is_the_path' });
			expect(prob.problem_params.file_path).toBe('this_is_the_path');

			prob.problem_params.set({ problem_pool_id: 12 });
			expect(prob.problem_params.problem_pool_id).toBe(12);
		});

		test('Test that problem params throw exception on invalid values.', () => {
			const prob = new SetProblem();
			// need to defined either a library_id, problem_pool_id or file_path
			expect(prob.problem_params.isValid()).toBe(false);

			prob.problem_params.file_path = '/this/is/the/path';
			expect(prob.problem_params.isValid()).toBe(true);

			prob.problem_params.weight = -1.5;
			expect(prob.problem_params.isValid()).toBe(false);

			prob.problem_params.weight = 11.5;
			expect(prob.problem_params.isValid()).toBe(true);

			const prob2 = new SetProblem({ problem_params: { file_path: '/this/is/the/path' } });
			expect(prob2.problem_params.isValid()).toBe(true);

			prob2.problem_params.library_id = 1.23;
			expect(prob2.problem_params.isValid()).toBe(false);

			prob2.problem_params.library_id = -1;
			expect(prob2.problem_params.isValid()).toBe(false);

			const prob3 = new SetProblem({ problem_params: { file_path: '/this/is/the/path' } });
			expect(prob3.problem_params.isValid()).toBe(true);

			prob3.problem_params.library_id = -1;
			expect(prob3.problem_params.isValid()).toBe(false);

			prob3.problem_params.library_id = 3.623;
			expect(prob3.problem_params.isValid()).toBe(false);
		});
	});

});

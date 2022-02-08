import { NonNegDecimalException, NonNegIntException } from 'src/common/models/parsers';
import { ParseableSetProblem, ParseableSetProblemParams, ProblemType, SetProblem } from 'src/common/models/problems';

const default_render_params = {
	problemSeed: 1234,
	permission_level: 0,
	outputFormat: 'ww3',
	answerPrefix: '',
	sourceFilePath: '',
	showHints: false,
	showSolutions: true,
	showPreviewButton: true,
	showCheckAnswersButton: true,
	showCorrectAnswersButton: true
};

const default_problem_params: ParseableSetProblemParams = {
	weight: 1,
	problem_pool_id: 0,
	library_id: 0,
	file_path:''
};

const default_problem_set: ParseableSetProblem = {
	problem_id: 0,
	set_id: 0,
	problem_number: 0,
	render_params: { ... default_render_params },
	problem_params: { ... default_problem_params }
};

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

test('Check that default rendering parameters are set.', () => {
	const prob = new SetProblem();
	expect(prob.render_params.toObject()).toStrictEqual(default_render_params);
});

test('Check the changing problem location params works', () => {
	const prob = new SetProblem();
	prob.problem_params.set({ file_path: 'path' });
	expect(prob.problem_params.file_path).toBe('path');
	prob.problem_params.set({ library_id: 1234 });
	expect(prob.problem_params.library_id).toBe(1234);
});

test('Check that changing the render params works', () => {
	const prob = new SetProblem();
	prob.setRenderParams({ problemSeed: 1234 });
	expect(prob.render_params.problemSeed).toBe(1234);
});

test('Check that cloning a library problem works', () => {
	const prob = new SetProblem();
	expect(prob.clone().toObject()).toStrictEqual(default_problem_set);
	expect(prob.clone() instanceof SetProblem).toBe(true);
});

test('Check setting set problem fields directly', () => {
	const prob = new SetProblem();
	prob.problem_number = 9;
	expect(prob.problem_number).toBe(9);
	prob.problem_number = '7';
	expect(prob.problem_number).toBe(7);

	prob.problem_id = 9;
	expect(prob.problem_id).toBe(9);
	prob.problem_id = '7';
	expect(prob.problem_id).toBe(7);

	prob.set_id = 5;
	expect(prob.set_id).toBe(5);
	prob.set_id = '11';
	expect(prob.set_id).toBe(11);

});

test('Check setting set problem fields using set()', () => {
	const prob = new SetProblem();
	prob.set({ problem_number: 9 });
	expect(prob.problem_number).toBe(9);
	prob.set({ problem_number: '7' });
	expect(prob.problem_number).toBe(7);

	prob.set({ problem_id: 9 });
	expect(prob.problem_id).toBe(9);
	prob.set({ problem_id: '7' });
	expect(prob.problem_id).toBe(7);

	prob.set({ set_id: 5 });
	expect(prob.set_id).toBe(5);
	prob.set({ set_id: '11' });
	expect(prob.set_id).toBe(11);

});

test('Check that invalid fields setting throw exceptions', () => {
	const prob = new SetProblem();
	expect(() => { prob.problem_number = -1; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_number = '-1'; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_number = 1.3; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_number = '1.5'; }).toThrow(NonNegIntException);

	expect(() => { prob.problem_id = -1; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_id = '-1'; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_id = 1.3; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_id = '1.5'; }).toThrow(NonNegIntException);

	expect(() => { prob.set_id = -1; }).toThrow(NonNegIntException);
	expect(() => { prob.set_id = '-1'; }).toThrow(NonNegIntException);
	expect(() => { prob.set_id = 1.3; }).toThrow(NonNegIntException);
	expect(() => { prob.set_id = '1.5'; }).toThrow(NonNegIntException);

});

test('Setting problem params directly', () => {
	const prob = new SetProblem();

	prob.problem_params.weight = 1.5;
	expect(prob.problem_params.weight).toBe(1.5);
	prob.problem_params.weight = '2.5';
	expect(prob.problem_params.weight).toBe(2.5);

	prob.problem_params.library_id = 1234;
	expect(prob.problem_params.library_id).toBe(1234);
	prob.problem_params.library_id = '4321';
	expect(prob.problem_params.library_id).toBe(4321);

	prob.problem_params.file_path = 'this_is_the_path';
	expect(prob.problem_params.file_path).toBe('this_is_the_path');

	prob.problem_params.problem_pool_id = 12;
	expect(prob.problem_params.problem_pool_id).toBe(12);
	prob.problem_params.problem_pool_id = '43';
	expect(prob.problem_params.problem_pool_id).toBe(43);

});

test('Setting problem params using set()', () => {
	const prob = new SetProblem();

	prob.problem_params.set({ weight: 1.5 });
	expect(prob.problem_params.weight).toBe(1.5);
	prob.problem_params.set({ weight: '2.5' });
	expect(prob.problem_params.weight).toBe(2.5);

	prob.problem_params.set({ library_id: 1234 });
	expect(prob.problem_params.library_id).toBe(1234);
	prob.problem_params.set({ library_id: '4321' });
	expect(prob.problem_params.library_id).toBe(4321);

	prob.problem_params.set({ file_path: 'this_is_the_path' });
	expect(prob.problem_params.file_path).toBe('this_is_the_path');

	prob.problem_params.set({ problem_pool_id: 12 });
	expect(prob.problem_params.problem_pool_id).toBe(12);
	prob.problem_params.set({ problem_pool_id: '43' });
	expect(prob.problem_params.problem_pool_id).toBe(43);

});

test('Test that problem params throw exception on invalid values.', () => {
	const prob = new SetProblem();

	expect(() => { prob.problem_params.weight = -1.5;}).toThrow(NonNegDecimalException);
	expect(() => { prob.problem_params.weight = '-1.5';}).toThrow(NonNegDecimalException);

	expect(() => { prob.problem_params.library_id = -1; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.library_id = '-1'; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.library_id = 1.3; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.library_id = '1.5'; }).toThrow(NonNegIntException);

	expect(() => { prob.problem_params.problem_pool_id = -1; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.problem_pool_id = '-1'; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.problem_pool_id = 1.3; }).toThrow(NonNegIntException);
	expect(() => { prob.problem_params.problem_pool_id = '1.5'; }).toThrow(NonNegIntException);

});

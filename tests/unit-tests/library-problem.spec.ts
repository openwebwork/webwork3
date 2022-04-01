import { LibraryProblem, ProblemType, ParseableLocationParams,
	ParseableLibraryProblem } from 'src/common/models/problems';

const default_library_params = {
	problemSeed: 1234,
	permissionLevel: 0,
	outputFormat: 'ww3',
	answerPrefix: '',
	sourceFilePath: '',
	showHints: false,
	showSolutions: true,
	showPreviewButton: true,
	showCheckAnswersButton: true,
	showCorrectAnswersButton: true
};

const default_problem_params: ParseableLocationParams = {
	problem_pool_id: 0,
	library_id: 0,
	file_path:''
};

const default_library_problem: ParseableLibraryProblem = {
	render_params: { ...default_library_params },
	location_params: { ...default_problem_params }
};

test('Test creation of a Library Problem', () => {
	const prob = new LibraryProblem();
	expect(prob instanceof LibraryProblem).toBe(true);

	// remove the problem_type from the toObject, since we can't set it in a
	// ParseableLibraryProblem
	const p = prob.toObject();
	delete p.problem_type;

	expect(p).toStrictEqual(default_library_problem);

	const prob2 = new LibraryProblem({ location_params: { file_path: '11234' } });
	expect(prob2.location_params.file_path).toBe('11234');

	expect(prob2.problem_type).toBe(ProblemType.LIBRARY);
});

test('Check that calling all_fields() and params() is correct', () => {
	const prob = new LibraryProblem();
	const library_problem_fields = ['render_params', 'location_params'];

	expect(prob.all_field_names.sort()).toStrictEqual(library_problem_fields.sort());
	expect(prob.param_fields.sort()).toStrictEqual(['render_params', 'location_params'].sort());

	expect(LibraryProblem.ALL_FIELDS.sort()).toStrictEqual(library_problem_fields.sort());

});

test('Check that default rendering parameters are set.', () => {
	const prob = new LibraryProblem();
	expect(prob.render_params.toObject()).toStrictEqual(default_library_params);
});

test('Check the changing problem location params works', () => {
	const prob = new LibraryProblem();
	prob.setLocationParams({ file_path: 'path' });
	expect(prob.location_params.file_path).toBe('path');
	prob.setLocationParams({ library_id: 1234 });
	expect(prob.location_params.library_id).toBe(1234);
});

test('Check that changing the render params works', () => {
	const prob = new LibraryProblem();
	prob.setRenderParams({ problemSeed: 1234 });
	expect(prob.render_params.problemSeed).toBe(1234);
});

test('Check that cloning a library problem works', () => {
	const prob = new LibraryProblem();
	const p = prob.clone().toObject();
	expect(p).toStrictEqual(default_library_problem);
	expect(prob.clone() instanceof LibraryProblem).toBe(true);
});

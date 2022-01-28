import { LibraryProblem } from 'src/common/models/problems';

const default_library_params = {
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

test('Test creation of a Library Problem', () => {
	const prob = new LibraryProblem();
	expect(prob instanceof LibraryProblem).toBe(true);

	const prob2 = new LibraryProblem({ library_params: { file_path: '11234' } });
	expect(prob2.library_params.file_path).toBe('11234');

});

test('Check that default rendering parameters are set.', () => {
	const prob = new LibraryProblem();
	expect(prob.render_params.toObject()).toStrictEqual(default_library_params);
});

test('Check the changing library params works', () => {
	const prob = new LibraryProblem();
	prob.setLibraryParams({ file_path: 'path' });
	expect(prob.library_params.file_path).toBe('path');
	prob.setLibraryParams({ library_id: 1234 });
	expect(prob.library_params.library_id).toBe(1234);
});

test('Check that changing the render params works', () => {
	const prob = new LibraryProblem();
	prob.setRenderParams({ problemSeed: 1234 });
	expect(prob.render_params.problemSeed).toBe(1234);
});

test('Check that cloning a library problem works', () => {
	const prob = new LibraryProblem();
	prob.setRenderParams({ problemSeed: 1234 });
	const library_params = { ...default_library_params };
	library_params.problemSeed = 1234;
	expect(prob.toObject()).toStrictEqual(prob.clone().toObject());
});

import { LibraryProblem } from 'src/store/models/problems-new';

test('Test creation of a Library Problem', () => {
	const prob = new LibraryProblem();
	expect(prob instanceof LibraryProblem).toBe(true);

	const prob2 = new LibraryProblem({ file_path: '11234' });
	expect(prob2.file_path).toBe('11234');

});

test('Check that default rendering parameters are set.', () => {
	const prob = new LibraryProblem();
	const default_params = {
		seed: 0,
		permission_level: 0,
		output_format: 'ww3',
		answer_prefix: '',
		show_hints: false,
		show_solutions: false,
		show_preview_button: false,
		show_check_answers_button: false,
		show_correct_answers_button: false
	};
	expect(prob.render_params).toStrictEqual(default_params);

});

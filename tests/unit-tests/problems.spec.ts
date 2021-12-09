// tests parsing and handling of problems

import { LibraryProblem, Problem } from 'src/store/models/problems';

test('Create a Valid LibraryProblem', () => {
	const problem1 = new LibraryProblem();
	expect(problem1 instanceof LibraryProblem).toBe(true);
	expect(problem1 instanceof Problem).toBe(true);
});

test('update the file path of a problem', () => {
	const problem1 = new LibraryProblem();
	problem1.setParams({ file_path: 'this is the file path' });
	expect(problem1.problem_params.file_path).toBe('this is the file path');

});

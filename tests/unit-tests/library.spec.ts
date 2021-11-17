// import { BooleanParseException, EmailParseException, NonNegIntException, UsernameParseException,
// RequiredFieldsException } from '@/store/models';
import { LibraryProblem } from 'src/store/models/library';

test('Create a Valid LibraryProblem', () => {
	const problem1 = new LibraryProblem();
	expect(problem1 instanceof LibraryProblem).toBe(true);
});

test('update the file path of a problem', () => {
	const problem1 = new LibraryProblem();
	problem1.setParams({ file_path: 'this is the file path' });
	expect(problem1.problem_params.file_path).toBe('this is the file path');

});

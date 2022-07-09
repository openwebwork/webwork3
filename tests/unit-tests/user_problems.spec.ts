// Testing UserProblems

import { DBUserProblem, ProblemType, UserProblem } from 'src/common/models/problems';

describe('Testing DB User Problems and User problems', () => {

	describe('Testing DB User Problems', () => {

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

		const default_db_user_problem = {
			render_params: { ...default_render_params },
			problem_params: { weight: 1 },
			user_problem_id: 0,
			set_problem_id: 0,
			user_set_id: 0,
			seed: 0,
			status: 0,
			problem_version: 1
		};

		describe('Creating generic database User Problems', () => {
			test('Create a Generic default DB User Problem', () => {
				const user_problem = new DBUserProblem();
				expect(user_problem).toBeInstanceOf(DBUserProblem);
				expect(user_problem.problem_type).toBe(ProblemType.USER);
				expect(user_problem.toObject()).toStrictEqual(default_db_user_problem);

			});

			test('Check that calling all_fields() and params() is correct', () => {
				const prob = new DBUserProblem();
				const user_problem_fields = ['render_params', 'problem_params', 'user_problem_id',
					'set_problem_id', 'user_set_id', 'seed', 'status', 'problem_version'];

				expect(prob.all_field_names.sort()).toStrictEqual(user_problem_fields.sort());
				expect(prob.param_fields.sort()).toStrictEqual(['problem_params', 'render_params']);
				expect(DBUserProblem.ALL_FIELDS.sort()).toStrictEqual(user_problem_fields.sort());
			});

			test('Check that cloning a db user problem works', () => {
				const prob = new DBUserProblem();
				expect(prob.clone().toObject()).toStrictEqual(default_db_user_problem);
				expect(prob.clone()).toBeInstanceOf(DBUserProblem);
			});
		});

		describe('Updating Generic DB User Problems', () => {

			test('Check the changing problem params directly works', () => {
				const prob = new DBUserProblem();
				prob.problem_params.weight = 2;
				expect(prob.problem_params.weight).toBe(2);

				prob.problem_params.library_id = 10;
				expect(prob.problem_params.library_id).toBe(10);

				prob.problem_params.file_path = 'path/to/file';
				expect(prob.problem_params.file_path).toBe('path/to/file');

				prob.problem_params.problem_pool_id = 15;
				expect(prob.problem_params.problem_pool_id).toBe(15);

			});

			test('Check the changing problem params using set() works', () => {
				const prob = new DBUserProblem();
				prob.problem_params.set({ weight: 2 });
				expect(prob.problem_params.weight).toBe(2);

				prob.problem_params.set({ library_id: 10 });
				expect(prob.problem_params.library_id).toBe(10);

				prob.problem_params.set({ file_path: 'path/to/file' });
				expect(prob.problem_params.file_path).toBe('path/to/file');

				prob.problem_params.set({ problem_pool_id: 15 });
				expect(prob.problem_params.problem_pool_id).toBe(15);
			});

			test('Check changes in fields set directly', () => {
				const prob = new DBUserProblem();
				prob.set_problem_id = 5;
				expect(prob.set_problem_id).toBe(5);

				prob.user_problem_id = 15;
				expect(prob.user_problem_id).toBe(15);

				prob.user_set_id = 8;
				expect(prob.user_set_id).toBe(8);

				prob.seed = 12345;
				expect(prob.seed).toBe(12345);

				prob.status = 2;
				expect(prob.status).toBe(2);

				prob.problem_version = 3;
				expect(prob.problem_version).toBe(3);
			});

			test('Check changes in fields using set()', () => {
				const prob = new DBUserProblem();
				prob.set({ set_problem_id: 5 });
				expect(prob.set_problem_id).toBe(5);

				prob.set({ user_problem_id: 15 });
				expect(prob.user_problem_id).toBe(15);

				prob.set({ user_set_id: 8 });
				expect(prob.user_set_id).toBe(8);

				prob.set({ seed: 12345 });
				expect(prob.seed).toBe(12345);

				prob.set({ status: 2 });
				expect(prob.status).toBe(2);

				prob.set({ problem_version: 3 });
				expect(prob.problem_version).toBe(3);

			});

			test('Check for valid db user problem fields.', () => {
				const prob = new DBUserProblem({ problem_params: { file_path: '/this/is/the/path' } });
				expect(prob.isValid()).toBe(true);

				prob.user_problem_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.user_problem_id = 23.34;
				expect(prob.isValid()).toBe(false);
				prob.user_problem_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.set_problem_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.set_problem_id = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.set_problem_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.user_set_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.user_set_id = 2.3;
				expect(prob.isValid()).toBe(false);
				prob.user_set_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.seed = -1;
				expect(prob.isValid()).toBe(false);
				prob.seed = 4.3;
				expect(prob.isValid()).toBe(false);
				prob.seed = 1324;
				expect(prob.isValid()).toBe(true);

				prob.status = -1;
				expect(prob.isValid()).toBe(false);
				prob.status = 2;
				expect(prob.isValid()).toBe(true);
				prob.status = 2.5;
				expect(prob.isValid()).toBe(true);

				prob.problem_version = -1;
				expect(prob.isValid()).toBe(false);
				prob.problem_version = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.problem_version = 11;
				expect(prob.isValid()).toBe(true);
			});
		});
	});

	describe('Testing User Problems', () => {

		const default_render_params = {
			problemSeed: 1234,
			permissionLevel: 0,
			outputFormat: 'ww3',
			answerPrefix: 'USER0_',
			sourceFilePath: '',
			showHints: false,
			showSolutions: false,
			showPreviewButton: true,
			showCheckAnswersButton: true,
			showCorrectAnswersButton: false
		};

		const default_user_problem = {
			render_params: { ...default_render_params },
			problem_params: {
				weight: 1,
			},
			user_problem_id: 0,
			set_problem_id: 0,
			user_id: 0,
			user_set_id: 0,
			seed: 0,
			status: 0,
			problem_version: 1,
			set_name: '',
			username: '',
			problem_number: 0
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
					'set_problem_id', 'user_id', 'user_set_id', 'seed', 'status', 'problem_version',
					'problem_number', 'username', 'set_name'];

				expect(prob.all_field_names.sort()).toStrictEqual(user_problem_fields.sort());
				expect(prob.param_fields.sort()).toStrictEqual(['problem_params', 'render_params']);

				expect(UserProblem.ALL_FIELDS.sort()).toStrictEqual(user_problem_fields.sort());

			});

			test('Check that cloning a user problem works', () => {
				const prob = new UserProblem();
				expect(prob.clone().toObject()).toStrictEqual(default_user_problem);
				expect(prob.clone()).toBeInstanceOf(UserProblem);
			});
		});

		describe('Updating User Problems', () => {
			test('Check the changing problem params directly works', () => {
				const prob = new UserProblem();
				prob.problem_params.weight = 2;
				expect(prob.problem_params.weight).toBe(2);

				prob.problem_params.library_id = 10;
				expect(prob.problem_params.library_id).toBe(10);

				prob.problem_params.file_path = 'path/to/file';
				expect(prob.problem_params.file_path).toBe('path/to/file');

				prob.problem_params.problem_pool_id = 15;
				expect(prob.problem_params.problem_pool_id).toBe(15);
			});

			test('Check the changing problem params using set() works', () => {
				const prob = new UserProblem();
				prob.problem_params.set({ weight: 2 });
				expect(prob.problem_params.weight).toBe(2);

				prob.problem_params.set({ library_id: 10 });
				expect(prob.problem_params.library_id).toBe(10);

				prob.problem_params.set({ file_path: 'path/to/file' });
				expect(prob.problem_params.file_path).toBe('path/to/file');

				prob.problem_params.set({ problem_pool_id: 15 });
				expect(prob.problem_params.problem_pool_id).toBe(15);
			});

			test('Check changes in fields set directly', () => {
				const prob = new UserProblem();
				prob.set_problem_id = 5;
				expect(prob.set_problem_id).toBe(5);

				prob.user_problem_id = 15;
				expect(prob.user_problem_id).toBe(15);

				prob.user_id = 8;
				expect(prob.user_id).toBe(8);

				prob.seed = 12345;
				expect(prob.seed).toBe(12345);

				prob.status = 2;
				expect(prob.status).toBe(2);

				prob.problem_version = 3;
				expect(prob.problem_version).toBe(3);

				prob.problem_number = 12;
				expect(prob.problem_number).toBe(12);

				prob.username = 'user';
				expect(prob.username).toBe('user');
				prob.username = 'user@myuniversity.edu';
				expect(prob.username).toBe('user@myuniversity.edu');

				prob.set_name = 'HW #1';
				expect(prob.set_name).toBe('HW #1');
			});

			test('Check changes in fields using set()', () => {
				const prob = new UserProblem();
				prob.set({ set_problem_id: 5 });
				expect(prob.set_problem_id).toBe(5);

				prob.set({ user_problem_id: 15 });
				expect(prob.user_problem_id).toBe(15);

				prob.set({ user_id: 8 });
				expect(prob.user_id).toBe(8);

				prob.set({ seed: 12345 });
				expect(prob.seed).toBe(12345);

				prob.set({ status: 2 });
				expect(prob.status).toBe(2);

				prob.set({ problem_version: 3 });
				expect(prob.problem_version).toBe(3);

				prob.set({ problem_number: 12 });
				expect(prob.problem_number).toBe(12);

				prob.set({ username: 'user' });
				expect(prob.username).toBe('user');
				prob.set({ username: 'user@myuniversity.edu' });
				expect(prob.username).toBe('user@myuniversity.edu');

				prob.set({ set_name: 'HW #1' });
				expect(prob.set_name).toBe('HW #1');

			});

			test('Check for valid user problem fields.', () => {
				const prob = new UserProblem({ problem_params: { file_path: '/this/is/the/path' } });
				// The username must be valid and the set_name cannot be the empty string.
				expect(prob.isValid()).toBe(false);
				prob.set({ username: 'homer', set_name: 'HW #1' });

				prob.user_problem_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.user_problem_id = 23.34;
				expect(prob.isValid()).toBe(false);
				prob.user_problem_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.set_problem_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.set_problem_id = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.set_problem_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.user_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.user_id = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.user_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.user_set_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.user_set_id = 2.3;
				expect(prob.isValid()).toBe(false);
				prob.user_set_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.set_id = -1;
				expect(prob.isValid()).toBe(false);
				prob.set_id = 2.3;
				expect(prob.isValid()).toBe(false);
				prob.set_id = 11;
				expect(prob.isValid()).toBe(true);

				prob.seed = -1;
				expect(prob.isValid()).toBe(false);
				prob.seed = 4.3;
				expect(prob.isValid()).toBe(false);
				prob.seed = 1324;
				expect(prob.isValid()).toBe(true);

				prob.status = -1;
				expect(prob.isValid()).toBe(false);
				prob.status = 2;
				expect(prob.isValid()).toBe(true);
				prob.status = 2.5;
				expect(prob.isValid()).toBe(true);

				prob.problem_version = -1;
				expect(prob.isValid()).toBe(false);
				prob.problem_version = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.problem_version = 11;
				expect(prob.isValid()).toBe(true);

				prob.problem_number = -1;
				expect(prob.isValid()).toBe(false);
				prob.problem_number = 8.32;
				expect(prob.isValid()).toBe(false);
				prob.problem_number = 11;
				expect(prob.isValid()).toBe(true);

				prob.username = 'homer the great!';
				expect(prob.isValid()).toBe(false);
				prob.username = 'homer@msn.com';
				expect(prob.isValid()).toBe(true);
			});
		});
	});
});

/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// set_problems.spec.ts
// Test the set problems store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { cleanIDs, loadCSV } from '../utils';
import { useCourseStore } from 'src/stores/courses';
import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';

import { Course } from 'src/common/models/courses';
import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { UserProblem, ParseableSetProblem, parseProblem, SetProblem, SetProblemParams, DBUserProblem,
	mergeUserProblem } from 'src/common/models/problems';
import { DBUserHomeworkSet, mergeUserSet, UserSet } from 'src/common/models/user_sets';
import { Dictionary, generic } from 'src/common/models';

import { parseBoolean, parseNonNegInt } from 'src/common/models/parsers';

const app = createApp({});

describe('Problem Set store tests', () => {
	let precalc_course: Course;
	// These are needed for multiple tests.
	let precalc_merged_problems: UserProblem[];
	let precalc_hw1_user_problems: UserProblem[];
	let precalc_problems_from_csv: Dictionary<generic | Dictionary<generic>>[];

	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as the admin in order to be authenticated for the rest of the test.
		await api.post('login', { username: 'admin', password: 'admin' });

		const problem_set_config = {
			params: ['set_params', 'set_dates' ],
			boolean_fields: ['set_visible'],
			param_boolean_fields: ['timed', 'enable_reduced_scoring', 'test_param'],
			param_non_neg_int_fields: ['quiz_duration']
		};

		const hw_sets_to_parse = await loadCSV('t/db/sample_data/hw_sets.csv', problem_set_config);
		const hw_sets_from_csv = hw_sets_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(set => new HomeworkSet(set));

		const quizzes_to_parse = await loadCSV('t/db/sample_data/quizzes.csv', problem_set_config);
		const quizzes_from_csv = quizzes_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(q => new Quiz(q));

		const review_sets_to_parse = await loadCSV('t/db/sample_data/review_sets.csv', problem_set_config);
		const review_sets_from_csv = review_sets_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(set => new ReviewSet(set));

		// combine quizzes, review sets and homework sets
		const problem_sets_from_csv = [...hw_sets_from_csv, ...quizzes_from_csv, ...review_sets_from_csv];

		// Load all problems from CSV files
		const problems_to_parse = await loadCSV('t/db/sample_data/problems.csv', {
			params: ['problem_params'],
			non_neg_int_fields: ['problem_number'],
			param_non_neg_float_fields: ['weight'],
			param_non_neg_int_fields: ['library_id', 'problem_pool_id']
		});

		// Filter only Precalc problems and remove any undefined library_ids
		precalc_problems_from_csv = problems_to_parse
			.filter(prob => prob.course_name === 'Precalculus');

		// Load the User Problem information from the csv file:
		const user_problems_from_csv = await loadCSV('t/db/sample_data/user_problems.csv', {
			params: [],
			non_neg_int_fields: ['problem_number', 'seed'],
			non_neg_float_fields: ['status']
		});

		// load all user problems in Precalc from CSV files and merge them with set problems.
		// Load the users from the csv file.
		const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
			boolean_fields: ['is_admin'],
			non_neg_int_fields: ['user_id']
		});

		precalc_merged_problems = user_problems_from_csv
			.filter(user_problem => user_problem.course_name === 'Precalculus')
			.map(user_problem => {
				const problem_set = problem_sets_from_csv.find(set => set.set_name === user_problem.set_name);
				const set_problem = precalc_problems_from_csv.find(prob =>
					prob.set_name === problem_set?.set_name && prob.problem_number === user_problem.problem_number);
				const user = users_to_parse.find(user => user.username === user_problem.username);
				return new UserProblem(Object.assign(problem_set, set_problem, user_problem, user));
			});

		precalc_hw1_user_problems = precalc_merged_problems.filter(prob => prob.set_name === 'HW #1');

		// We'll need the courses as well.
		const courses_store = useCourseStore();
		await courses_store.fetchCourses();
		precalc_course = courses_store.courses.find(course => course.course_name === 'Precalculus') as Course;

		// Fetch all problem sets:
		const problem_set_store = useProblemSetStore();
		await problem_set_store.fetchProblemSets(precalc_course.course_id);
		await problem_set_store.fetchAllUserSets(precalc_course.course_id);

		// Add the precalc course to the session;
		const session_store = useSessionStore();
		session_store.setCourse({
			course_id: precalc_course.course_id,
			course_name: precalc_course.course_name
		});
	});

	describe('fetching set problems for a course', () => {
		test('fetching problems for a course.', async () => {
			const set_problem_store = useSetProblemStore();
			await set_problem_store.fetchSetProblems(precalc_course.course_id);
			expect(set_problem_store.set_problems.length).toBeGreaterThan(0);

			// Create Problems as Models and then convert to Object to compare.
			const precalc_problems = precalc_problems_from_csv
				.map(prob => parseProblem(prob as ParseableSetProblem, 'Set') as SetProblem);
			expect(cleanIDs(set_problem_store.set_problems))
				.toStrictEqual(cleanIDs(precalc_problems));
		});
	});

	describe('CRUD tests for set problems', () => {
		let new_problem: SetProblem;
		let updated_problem: SetProblem;
		test('Add a set problem to a set', async () => {
			const problem_set_store = useProblemSetStore();
			const set_problem_store = useSetProblemStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			const path = 'path/to/the/problem.pg';

			// grab the set problems for HW #1 so we know which is the next problem number.
			const probs = set_problem_store.findSetProblems({ set_name: 'HW #1' });

			const new_set_problem = new SetProblem({
				set_id: hw1?.set_id,
				problem_number: probs[probs.length - 1].problem_number + 1,
				problem_params: new SetProblemParams({
					weight: 1,
					file_path: path
				})
			});
			new_problem = await set_problem_store.addSetProblem(new_set_problem);
			expect(cleanIDs(new_problem)).toStrictEqual(cleanIDs(new_set_problem));
		});

		test('Update a set problem', async () => {
			const set_problem_store = useSetProblemStore();
			updated_problem = new_problem.clone();
			updated_problem.problem_params.weight = 2;

			const problem_from_server = await set_problem_store.updateSetProblem(updated_problem);
			expect(problem_from_server).toStrictEqual(updated_problem);
		});

		test('Delete a set problem', async () => {
			const set_problem_store = useSetProblemStore();
			const problems = set_problem_store.findSetProblems({ set_name: 'HW #1' });
			const deleted_problem = await set_problem_store.deleteSetProblem(new_problem);
			expect(deleted_problem).toStrictEqual(updated_problem);
			expect(set_problem_store.findSetProblems({ set_name: 'HW #1' }).length)
				.toBe(problems.length - 1);
		});
	});

	describe('Fetch user problems', () => {
		test('Fetch all User Problems for a set in a course', async () => {
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course.course_id);
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' }) ?? new ProblemSet();
			const set_problems_store = useSetProblemStore();
			await set_problems_store.fetchUserProblems(hw1.set_id);
			const hw1_user_problems = set_problems_store.findUserProblems({ set_name: 'HW #1' });
			expect(cleanIDs(precalc_hw1_user_problems)).toStrictEqual(cleanIDs(hw1_user_problems));
		});
	});

	describe('CRUD operations on user problems', () => {
		let added_hw: HomeworkSet;
		let added_user_set: UserSet;
		let added_user_problem: UserProblem;
		let updated_user_problem: UserProblem;
		let new_problem: SetProblem;
		test('Add a new ProblemSet, UserSet, SetProblem and DBUserProblem ', async () => {
			// Note: adding a Problem Set, UserSet and SetProblem are done elsewhere,
			// so no need to test that these are working.  Just add them to make testing
			// DBUserProblems easier.
			const problem_set_store = useProblemSetStore();
			const set_problem_store = useSetProblemStore();
			const hw = new HomeworkSet({
				course_id: precalc_course.course_id,
				set_name: 'HW #9'
			});
			added_hw = await problem_set_store.addProblemSet(hw) as HomeworkSet;

			const new_set_problem = new SetProblem({
				set_id: added_hw?.set_id ?? 0,
				problem_params: {
					file_path: 'path/to/the/problem.pg'
				}
			});
			new_problem = await set_problem_store.addSetProblem(new_set_problem);

			const users_store = useUserStore();
			await users_store.fetchCourseUsers(precalc_course.course_id);
			await users_store.fetchGlobalCourseUsers(precalc_course.course_id);
			const user = users_store.course_users[0];

			const db_user_set = new DBUserHomeworkSet({
				course_user_id: user.course_user_id,
				set_id: added_hw.set_id
			});
			const user_set = mergeUserSet(added_hw, db_user_set, user) ?? new UserSet();
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();

			const user_problem = mergeUserProblem(new_set_problem,
				new DBUserProblem({
					user_set_id: added_user_set.user_set_id,
					problem_id: new_problem.problem_id,
					seed: 4321
				}),
				user_set);

			added_user_problem = await set_problem_store.addUserProblem(user_problem);
			expect(cleanIDs(user_problem)).toStrictEqual(cleanIDs(added_user_problem));
		});

		test('Update a user problem', async () => {
			const set_problem_store = useSetProblemStore();
			added_user_problem.problem_version = 2;
			added_user_problem.problem_params.set({
				file_path: 'a/different/file.pg'
			});
			updated_user_problem = await set_problem_store.updateUserProblem(added_user_problem);
			expect(cleanIDs(updated_user_problem)).toStrictEqual(cleanIDs(added_user_problem));
		});

		test('Delete a user problem', async () => {
			const set_problem_store = useSetProblemStore();
			const deleted_problem = await set_problem_store.deleteUserProblem(updated_user_problem);
			expect(cleanIDs(deleted_problem)).toStrictEqual(cleanIDs(updated_user_problem));
		});

		// clean up some created sets.
		afterAll(async () => {
			const problem_set_store = useProblemSetStore();
			const set_problem_store = useSetProblemStore();
			await problem_set_store.deleteProblemSet(added_hw);
			await problem_set_store.deleteUserSet(added_user_set);
			await set_problem_store.deleteSetProblem(new_problem);
		});
	});

	describe('Testing Merged User Problems for a set in a course.', () => {
		test('Testing merged user problems', async () => {
			// Reload all of the data from the database.
			// Not sure why this is needed, but maybe something isn't rest from previous tests.
			const set_problem_store = useSetProblemStore();
			await set_problem_store.fetchSetProblems(precalc_course.course_id);
			await set_problem_store.fetchUserProblems(precalc_course.course_id);
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course.course_id);
			await problem_set_store.fetchAllUserSets(precalc_course.course_id);
			const users_store = useUserStore();
			await users_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await users_store.fetchCourseUsers(precalc_course.course_id);
			expect(cleanIDs(precalc_hw1_user_problems))
				.toStrictEqual(cleanIDs(set_problem_store.user_problems));
		});
	});

	describe('Testing Merged User Problems for a user in a course.', () => {
		test('Testing merged user problems', async () => {
			const set_problem_store = useSetProblemStore();
			const single_user_problems = precalc_merged_problems
				.filter(prob => prob.username === 'homer');
			const user_store = useUserStore();
			// user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			const homer = user_store.findCourseUser({ username: 'homer' });
			await set_problem_store.fetchUserProblemsForUser(homer.user_id);
			expect(cleanIDs(single_user_problems))
				.toStrictEqual(cleanIDs(set_problem_store.user_problems));
		});
	});
});

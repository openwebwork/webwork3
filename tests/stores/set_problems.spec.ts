/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// set_problems.spec.ts
// Test the set problems store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import { cleanIDs, loadCSV } from '../utils';
import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import { useUserStore } from 'src/stores/users';
import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { parseBoolean, parseNonNegInt } from 'src/common/models/parsers';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';
import { LibraryProblem, ParseableSetProblem, parseProblem, SetProblem, SetProblemParams,
	UserProblem } from 'src/common/models/problems';
import { UserHomeworkSet, UserSet } from 'src/common/models/user_sets';

const app = createApp({});

describe('Problem Set store tests', () => {
	let precalc_course: Course;
	let precalc_hw1_user_problems: UserProblem[];
	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		const problem_set_config = {
			params: ['set_params', 'set_dates' ],
			boolean_fields: ['set_visible']
		};

		const hw_sets_to_parse = await loadCSV('t/db/sample_data/hw_sets.csv', problem_set_config);
		// Do some parsing cleanup.
		const hw_sets_from_csv = hw_sets_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(set => new HomeworkSet(set));
		hw_sets_from_csv.forEach(set => {
			set.set_params.enable_reduced_scoring = parseBoolean(set.set_params.enable_reduced_scoring);
		});

		const quizzes_to_parse = await loadCSV('t/db/sample_data/quizzes.csv', problem_set_config);
		const quizzes_from_csv = quizzes_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(q => new Quiz(q));
		// Do some parsing cleanup.
		quizzes_from_csv.forEach(q => {
			q.set_params.timed = parseBoolean(q.set_params.timed);
			q.set_params.quiz_duration = parseNonNegInt(q.set_params.quiz_duration);
		});

		const review_sets_to_parse = await loadCSV('t/db/sample_data/review_sets.csv', problem_set_config);
		const review_sets_from_csv = review_sets_to_parse.filter(set => set.course_name === 'Precalculus')
			.map(set => new ReviewSet(set));
		// Do some parsing cleanup.
		review_sets_from_csv.forEach(set => {
			set.set_params.test_param = parseBoolean(set.set_params.test_param);
		});
		// combine quizzes, review sets and homework sets
		// const problem_sets_from_csv = [...hw_sets_from_csv, ...quizzes_from_csv, ...review_sets_from_csv];

		// Load the User Problem information from the csv file:
		const user_problems_from_csv = await loadCSV('t/db/sample_data/user_problems.csv', {
			params: [],
			non_neg_fields: ['problem_number', 'seed']
		});

		// const precalc_user_problems = user_problems_from_csv
		// .filter(prob => prob.course_name === 'Precalculus')
		// .map(prob => new UserProblem(prob));

		precalc_hw1_user_problems = user_problems_from_csv
			.filter(prob => prob.course_name === 'Precalculus' && prob.set_name === 'HW #1')
			.map(prob => new UserProblem(prob));

		// Load the users from the csv file.
		// const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
		// boolean_fields: ['is_admin'],
		// non_neg_fields: ['user_id']
		// });
		// Do some parsing and cleanup.
		// const all_users_from_csv = users_to_parse.map(user => new User(user));
		// const all_precalc_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
		// .map(user => new User(user));
		// const precalc_merged_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
		// .map(user => new MergedUser(user));

		// We'll need the courses as well.
		const courses_store = useCourseStore();
		await courses_store.fetchCourses();
		precalc_course = courses_store.courses.find(course => course.course_name === 'Precalculus') as Course;

		// Fetch all problem sets:
		const problem_set_store = useProblemSetStore();
		await problem_set_store.fetchProblemSets(precalc_course.course_id);

		// Add the precalc course to the session;
		const session_store = useSessionStore();
		session_store.setCourse({
			course_id: precalc_course.course_id,
			course_name: precalc_course.course_name
		});
	});

	let precalc_problems_from_csv: SetProblem[];
	describe('fetching set problems for a course', () => {
		test('fetching problems for a course.', async () => {
			const set_problem_store = useSetProblemStore();
			await set_problem_store.fetchSetProblems(precalc_course.course_id);
			expect(set_problem_store.set_problems.length).toBeGreaterThan(0);

			const problems_config = {
				params: ['problem_params'],
				non_neg_fields: ['problem_number']
			};

			const problems_to_parse = await loadCSV('t/db/sample_data/problems.csv', problems_config);

			// Filter only Precalc problems and remove any undefined library_ids
			const precalc_probs = problems_to_parse.filter(prob => prob.course_name === 'Precalculus');
			precalc_probs.forEach(prob => {
				const p = prob as ParseableSetProblem;
				if (!p.problem_params?.library_id) {
					delete p.problem_params?.library_id;
				}
			});

			// Create Problems as Models and then convert to Object to compare.
			precalc_problems_from_csv = precalc_probs
				.map(prob => parseProblem(prob as ParseableSetProblem, 'Set') as SetProblem);
			expect(cleanIDs(set_problem_store.set_problems))
				.toStrictEqual(cleanIDs(precalc_problems_from_csv));
		});
	});

	describe('CRUD tests for set problems', () => {
		let new_problem: SetProblem;
		let updated_problem: SetProblem;
		test('Add a set problem to a set', async () => {
			const problem_set_store = useProblemSetStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			const path = 'path/to/the/problem.pg';
			const lib_prob = new LibraryProblem({
				location_params: {
					file_path: path
				}
			});
			const set_problem_store = useSetProblemStore();
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
			new_problem = await set_problem_store.addSetProblem({ set_id: hw1?.set_id ?? 0, problem: lib_prob });
			expect(cleanIDs(new_problem)).toStrictEqual(cleanIDs(new_set_problem));
		});

		test('Update a set problem', async () => {
			const set_problem_store = useSetProblemStore();
			updated_problem = new_problem.clone();
			updated_problem.problem_params.weight = 2;

			const problem_from_server = await set_problem_store.updateSetProblem({
				set_id: updated_problem.set_id,
				problem_id: updated_problem.problem_id,
				props: updated_problem.toObject() as ParseableSetProblem
			});
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
			const problem_set_store = useProblemSetStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' }) ?? new ProblemSet();
			const set_problems_store = useSetProblemStore();
			await set_problems_store.fetchUserProblems(hw1.set_id);
			// const hw1_problems = set_problems_store.findSetProblems({ set_name: 'HW #1' });
			const hw1_user_problems = set_problems_store.findUserProblems({ set_name: 'HW #1' });
			expect(cleanIDs(precalc_hw1_user_problems)).toStrictEqual(cleanIDs(hw1_user_problems));
		});
	});

	describe('CRUD operations on user problems', () => {
		let added_hw: HomeworkSet;
		let added_user_set: UserSet;
		let added_user_problem: UserProblem;
		let new_problem: SetProblem;
		test('Add a new ProblemSet, UserSet, SetProblem and UserProblem ', async () => {
			// Note: adding a Problem Set, UserSet and SetProblem are done elsewhere,
			// so no need to test that these are working.  Just add them to make testing
			// UserProblems easier.
			const problem_set_store = useProblemSetStore();
			const hw = new HomeworkSet({
				course_id: precalc_course.course_id,
				set_name: 'HW #9'
			});
			added_hw = await problem_set_store.addProblemSet(hw) as HomeworkSet;

			const lib_prob = new LibraryProblem({
				location_params: {
					file_path: 'path/to/the/problem.pg'
				}
			});
			const set_problem_store = useSetProblemStore();
			// grab the set problems for HW #1 so we know which is the next problem number.
			// const probs = set_problem_store.findSetProblems({ set_name: 'HW #1' });
			new_problem = await set_problem_store.addSetProblem({ set_id: added_hw?.set_id ?? 0, problem: lib_prob });

			const users_store = useUserStore();
			await users_store.fetchCourseUsers(precalc_course.course_id);
			await users_store.fetchGlobalCourseUsers(precalc_course.course_id);
			const user = users_store.course_users[0];
			// console.log(user);
			const user_set = new UserHomeworkSet({
				course_user_id: user.course_user_id,
				set_id: added_hw.set_id
			});
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			console.log(added_user_set);

			const user_problem = new UserProblem({
				user_set_id: added_user_set.user_set_id,
				problem_id: new_problem.problem_id,
				seed: 4321
			});
			added_user_problem = await set_problem_store.addUserProblem(user_problem);
			console.log(added_user_problem);
			expect(cleanIDs(user_problem)).toStrictEqual(cleanIDs(added_user_problem));
		});

		test('Delete a user problem', async () => {
			const set_problem_store = useSetProblemStore();
			const deleted_problem = await set_problem_store.deleteUserProblem(added_user_problem);
			expect(cleanIDs(deleted_problem)).toStrictEqual(cleanIDs(added_user_problem));
		});
	});
});

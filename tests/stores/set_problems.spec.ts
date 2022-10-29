/** @jest-environment jsdom */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// Test the set problems store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import { useCourseStore } from 'src/stores/courses';
import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';

import { Course } from 'src/common/models/courses';
import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { UserProblem, ParseableSetProblem, parseProblem, SetProblem, SetProblemParams, DBUserProblem,
	mergeUserProblem, LibraryProblem } from 'src/common/models/problems';
import { DBUserHomeworkSet, mergeUserSet, UserSet } from 'src/common/models/user_sets';
import { Dictionary, generic } from 'src/common/models';

import { cleanIDs } from '../utils';
import { checkPassword } from 'src/common/api-requests/session';

const app = createApp({});

describe('Problem Set store tests', () => {
	let precalc_course: Course;
	// These are needed for multiple tests.
	const precalc_merged_problems: UserProblem[] = [];
	let precalc_hw1_user_problems: UserProblem[];
	const precalc_problems_from_json: Dictionary<generic | Dictionary<generic>>[] = [];

	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as Precalculus instructor in order to be authenticated for the rest of the test.
		const session_info = await checkPassword({ username: 'frink', password: 'frink' });
		const session_store = useSessionStore();
		session_store.updateSessionInfo(session_info);

		const problem_sets_from_json: ProblemSet[] = [];

		(await import('../../t/db/sample_data/hw_sets.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new HomeworkSet(set)));

		(await import('../../t/db/sample_data/quizzes.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new Quiz(set)));

		(await import('../../t/db/sample_data/review_sets.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new ReviewSet(set)));

		// Load problems from the JSON file and extract the precalc problems.
		(await import('../../t/db/sample_data/problems.json')).default
			.find((course) => course.course_name === 'Precalculus')?.sets.forEach((set) => {
				set.problems.forEach((problem) => {
					precalc_problems_from_json.push({
						problem_number: problem.problem_number,
						problem_params: problem.problem_params,
						set_name: set.set_name
					});
				});
			});

		// Load the users from the JSON file.
		const users_to_parse = (await import('../../t/db/sample_data/users.json')).default;

		// Load the user problem information from the JSON file and merge them with the set problems.
		(await import('../../t/db/sample_data/user_problems.json')).default
			.find((course) => course.course_name === 'Precalculus')?.sets.forEach((set_info) => {
				const problem_set = problem_sets_from_json.find((set) => set.set_name === set_info.set_name);
				set_info.problems.forEach((problem_info) => {
					const set_problem = precalc_problems_from_json.find((prob) =>
						prob.set_name === problem_set?.set_name && prob.problem_number === problem_info.problem_number);
					problem_info.users.forEach((user_info) => {
						const user = users_to_parse.find(user => user.username === user_info.username);
						precalc_merged_problems.push(
							new UserProblem(Object.assign({}, set_problem, user_info.user_problem, user))
						);
					});

				});
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
		await session_store.fetchUserCourses();
		session_store.setCourse(precalc_course.course_id);
	});

	describe('fetching set problems for a course', () => {
		test('fetching problems for a course.', async () => {
			const set_problem_store = useSetProblemStore();
			await set_problem_store.fetchSetProblems(precalc_course.course_id);
			expect(set_problem_store.set_problems.length).toBeGreaterThan(0);

			// Create Problems as Models and then convert to Object to compare.
			const precalc_problems = precalc_problems_from_json
				.map(prob => parseProblem(prob as ParseableSetProblem, 'Set') as SetProblem);

			expect(cleanIDs(set_problem_store.set_problems)).toStrictEqual(cleanIDs(precalc_problems));
		});
	});

	describe('CRUD tests for set problems', () => {
		let added_set_problem: SetProblem;
		let updated_problem: SetProblem;
		test('Add a set problem to a set', async () => {
			const problem_set_store = useProblemSetStore();
			const set_problem_store = useSetProblemStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			expect(hw1?.set_name).toStrictEqual('HW #1');

			// grab the set problems for HW #1 so we know which is the next problem number.
			const probs = set_problem_store.findSetProblems({ set_name: 'HW #1' });
			expect(probs.length).toBeGreaterThan(0);

			const problem_number = probs[probs.length - 1].problem_number + 1;

			const new_set_problem = new SetProblem({
				set_id: hw1?.set_id,
				problem_number,
				problem_params: new SetProblemParams({
					weight: 1,
					file_path: 'path/to/the/problem.pg'
				})
			});
			const library_problem = new LibraryProblem({ location_params: { file_path: 'path/to/the/problem.pg' } });
			expect(library_problem.isValid()).toBe(true);
			added_set_problem = await set_problem_store.addSetProblem(library_problem, hw1?.set_id ?? 0);

			expect(cleanIDs(added_set_problem)).toStrictEqual(cleanIDs(new_set_problem));
		});

		test('Update a set problem', async () => {
			const set_problem_store = useSetProblemStore();
			updated_problem = added_set_problem.clone();
			updated_problem.problem_params.weight = 2;

			const problem_from_server = await set_problem_store.updateSetProblem(updated_problem);
			expect(problem_from_server).toStrictEqual(updated_problem);
		});

		test('Delete a set problem', async () => {
			const set_problem_store = useSetProblemStore();
			const problems = set_problem_store.findSetProblems({ set_name: 'HW #1' });
			const deleted_problem = await set_problem_store.deleteSetProblem(added_set_problem);
			expect(deleted_problem).toStrictEqual(updated_problem);
			expect(set_problem_store.findSetProblems({ set_name: 'HW #1' }).length)
				.toBe(problems.length - 1);
		});
	});

	describe('Test that invalid set problems are handled correctly', () => {
		test('Try to add an invalid set problem', async () => {
			const problem_set_store = useProblemSetStore();
			const set_problem_store = useSetProblemStore();

			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });

			// This user has an invalid username
			const library_problem = new LibraryProblem({
			});
			expect(library_problem.isValid()).toBe(false);
			await expect(async () => { await set_problem_store.addSetProblem(library_problem, hw1?.set_id ?? 0); })
				.rejects.toThrow('The added problem is invalid');
		});

		test('Try to update an invalid set problem', async () => {
			const set_problem_store = useSetProblemStore();

			const prob1 = set_problem_store.findSetProblems({ set_name: 'HW #1' })[0].clone();

			if (prob1) {
				prob1.problem_number = -8;
				expect(prob1.isValid()).toBe(false);
				await expect(async () => { await set_problem_store.updateSetProblem(prob1); })
					.rejects.toThrow('The updated set problem is invalid');
			} else {
				throw 'This should not have be thrown.  The set problem is not defined.';
			}
		});
	});

	// sort, clean up the status and clean up the _id tags.
	const sortAndClean = (user_problems: UserProblem[]) => {
		const probs = user_problems.sort((a, b) =>
			a.username < b.username ? -1 : a.username > b.username ? 1 : 0 ||
			a.set_name < b.set_name ? -1 : a.set_name > b.set_name ? 1 : 0 ||
			a.problem_number - b.problem_number
		);
		probs.forEach(user_problem => {
			user_problem.status = parseFloat(`${user_problem.status}`);
		});
		return cleanIDs(probs);
	};

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
			expect(sortAndClean(precalc_hw1_user_problems)).toStrictEqual(sortAndClean(hw1_user_problems));
		});
	});

	describe('CRUD operations on user problems', () => {
		let added_hw: HomeworkSet;
		let added_user_set: UserSet;
		let added_user_problem: UserProblem;
		let updated_user_problem: UserProblem;
		let added_set_problem: SetProblem;
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

			const library_problem = new LibraryProblem({ location_params: { file_path: 'path/to/the/problem.pg' } });
			added_set_problem = await set_problem_store.addSetProblem(library_problem, added_hw.set_id);

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

			const user_problem = mergeUserProblem(added_set_problem,
				new DBUserProblem({
					user_set_id: added_user_set.user_set_id,
					set_problem_id: added_set_problem.set_problem_id,
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

			updated_user_problem = await set_problem_store.updateUserProblem(added_user_problem)
				?? new UserProblem();
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
			// Note: the reverse order is important here.  If the set is deleted first,
			// then DBIx::class automatically deletes related data.
			await set_problem_store.deleteSetProblem(added_set_problem);
			await problem_set_store.deleteUserSet(added_user_set);
			await problem_set_store.deleteProblemSet(added_hw);
		});
	});

	describe('Testing Merged User Problems for a set in a course.', () => {
		test('Testing merged user problems', async () => {
			// Reload all of the data from the database.
			// Not sure why this is needed, but maybe something isn't reset from previous tests.
			const set_problem_store = useSetProblemStore();
			await set_problem_store.fetchSetProblems(precalc_course.course_id);
			await set_problem_store.fetchUserProblems(precalc_course.course_id);
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course.course_id);
			await problem_set_store.fetchAllUserSets(precalc_course.course_id);
			const users_store = useUserStore();
			await users_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await users_store.fetchCourseUsers(precalc_course.course_id);
			expect(sortAndClean(precalc_hw1_user_problems))
				.toStrictEqual(sortAndClean(set_problem_store.user_problems));
		});
	});

	describe('Testing Merged User Problems for a user in a course.', () => {
		test('Testing merged user problems', async () => {
			const set_problem_store = useSetProblemStore();
			const single_user_problems = precalc_merged_problems
				.filter(prob => prob.username === 'homer');
			const user_store = useUserStore();

			const homer = user_store.findCourseUser({ username: 'homer' });
			await set_problem_store.fetchUserProblemsForUser(homer.user_id);

			expect(sortAndClean(single_user_problems))
				.toStrictEqual(sortAndClean(set_problem_store.user_problems));
		});
	});
});

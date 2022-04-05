/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

// problem_sets.spec.ts
// Test the problem sets Store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { cleanIDs, loadCSV } from '../utils';
import { parseBoolean, parseNonNegInt } from 'src/common/models/parsers';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import { LibraryProblem, SetProblemParams, ParseableSetProblem, parseProblem,
	Problem, SetProblem } from 'src/common/models/problems';
import { useSessionStore } from 'src/stores/session';
import { useUserStore } from 'src/stores/users';
import { UserHomeworkSet, UserQuiz, UserReviewSet, UserSet } from 'src/common/models/user_sets';

const app = createApp({});

describe('Problem Set store tests', () => {
	let problem_sets_from_csv: ProblemSet[];
	let precalc_course: Course;
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
		problem_sets_from_csv = [...hw_sets_from_csv, ...quizzes_from_csv, ...review_sets_from_csv];

		// We'll need the courses as well.
		const courses_store = useCourseStore();
		await courses_store.fetchCourses();
		precalc_course = courses_store.courses.find(course => course.course_name === 'Precalculus') as Course;

		// Add the precalc course to the session;
		const session_store = useSessionStore();
		session_store.setCourse({
			course_id: precalc_course.course_id,
			course_name: precalc_course.course_name
		});
	});

	describe('Fetch problem sets', () => {

		test('Fetch the Problem Sets for a course', async () => {
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course?.course_id ?? 0);
			expect(problem_set_store.problem_sets.length).toBeGreaterThan(0);
			expect(cleanIDs(problem_set_store.problem_sets)).toStrictEqual(cleanIDs(problem_sets_from_csv));
		});

	});

	describe('CRUD test for homework sets', () => {

		test('Add a new Homework Set', async () => {
			const problem_set_store = useProblemSetStore();
			const new_set_info = {
				set_name: 'HW #9',
				course_id: precalc_course.course_id,
				set_visible: true,
				set_params: {
					enable_reduced_scoring: true
				},
				set_dates: {
					open: 1000,
					reduced_scoring: 1500,
					due: 2000,
					answer: 3000
				}
			};
			const new_set = new HomeworkSet(new_set_info);
			await problem_set_store.addProblemSet(new_set);
			const new_set_retrieved = problem_set_store.findProblemSet({ set_name: 'HW #9' });
			expect(cleanIDs(new_set_retrieved as HomeworkSet))
				.toStrictEqual(cleanIDs(new_set));

		});

		test('Update a Homework Set', async () => {
			const problem_set_store = useProblemSetStore();
			const problem_set = (problem_set_store.findProblemSet({ set_name: 'HW #9' }) as HomeworkSet).clone();
			problem_set.set_params.enable_reduced_scoring = false;
			await problem_set_store.updateSet(problem_set);
			const updated_set = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as HomeworkSet).clone();
			expect(updated_set?.set_params.enable_reduced_scoring).toBeFalsy();

			// update the answer date
			const new_answer_date = updated_set.set_dates.answer + 100;
			updated_set.set_dates.answer = new_answer_date;
			await problem_set_store.updateSet(updated_set);
			const updated_set2 = problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as HomeworkSet;
			expect(updated_set2.set_dates.answer).toBe(new_answer_date);
		});

		test('Delete a Homework Set', async () => {
			const problem_set_store = useProblemSetStore();
			const set_to_delete = problem_set_store.findProblemSet({ set_name: 'HW #9' });
			const deleted_set = await problem_set_store.deleteProblemSet(set_to_delete as ProblemSet);
			// Check that the deleted_set is the same as the original
			expect(deleted_set.toObject()).toStrictEqual(set_to_delete?.toObject());
			const is_the_set_deleted = problem_set_store.findProblemSet({ set_name: 'HW #9' });
			expect(is_the_set_deleted).toBeUndefined();
		});
	});

	describe('CRUD test for quizzes', () => {

		test('Add a new Quiz', async () => {
			const problem_set_store = useProblemSetStore();
			const new_set_info = {
				set_name: 'Quiz #9',
				course_id: precalc_course.course_id,
				set_visible: true,
				set_params: {
					timed: true
				},
				set_dates: {
					open: 1000,
					due: 2000,
					answer: 3000
				}
			};
			const new_set = new Quiz(new_set_info);
			await problem_set_store.addProblemSet(new_set);
			const new_set_retrieved = problem_set_store.findProblemSet({ set_name: 'Quiz #9' });
			expect(cleanIDs(new_set_retrieved as Quiz))
				.toStrictEqual(cleanIDs(new_set));

		});

		test('Update a Quiz', async () => {
			const problem_set_store = useProblemSetStore();
			const problem_set = (problem_set_store.findProblemSet({ set_name: 'Quiz #9' }) as Quiz).clone();
			problem_set.set_params.timed = false;
			await problem_set_store.updateSet(problem_set);
			const updated_set = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as HomeworkSet).clone();
			expect(updated_set?.set_params.enable_reduced_scoring).toBeFalsy();

			// update the answer date
			const new_answer_date = updated_set.set_dates.answer + 100;
			updated_set.set_dates.answer = new_answer_date;
			await problem_set_store.updateSet(updated_set);
			const updated_set2 = problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as Quiz;
			expect(updated_set2.set_dates.answer).toBe(new_answer_date);
		});

		test('Delete a Quiz', async () => {
			const problem_set_store = useProblemSetStore();
			const set_to_delete = problem_set_store.findProblemSet({ set_name: 'Quiz #9' });
			const deleted_set = await problem_set_store.deleteProblemSet(set_to_delete as ProblemSet);
			// Check that the deleted_set is the same as the original
			expect(deleted_set.toObject()).toStrictEqual(set_to_delete?.toObject());
			const is_the_set_deleted = problem_set_store.findProblemSet({ set_name: 'Quiz #9' });
			expect(is_the_set_deleted).toBeUndefined();
		});
	});

	describe('CRUD test for review sets', () => {

		test('Add a new Review Set', async () => {
			const problem_set_store = useProblemSetStore();
			const new_set_info = {
				set_name: 'Review Set #9',
				course_id: precalc_course.course_id,
				set_visible: true,
				set_params: {
					test_param: true
				},
				set_dates: {
					open: 1000,
					closed: 2000
				}
			};
			const new_set = new ReviewSet(new_set_info);
			await problem_set_store.addProblemSet(new_set);
			const new_set_retrieved = problem_set_store.findProblemSet({ set_name: 'Review Set #9' });
			expect(cleanIDs(new_set_retrieved as ReviewSet))
				.toStrictEqual(cleanIDs(new_set));

		});

		test('Update a Review Set', async () => {
			const problem_set_store = useProblemSetStore();
			const problem_set = (problem_set_store.findProblemSet({ set_name: 'Review Set #9' }) as ReviewSet).clone();
			problem_set.set_params.test_param = false;
			await problem_set_store.updateSet(problem_set);
			const updated_set = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as ReviewSet).clone();
			expect(updated_set?.set_params.test_param).toBeFalsy();

			// update the closed date
			const new_closed_date = updated_set.set_dates.closed + 100;
			updated_set.set_dates.closed = new_closed_date;
			await problem_set_store.updateSet(updated_set);
			const updated_set2 = problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as ReviewSet;
			expect(updated_set2.set_dates.closed).toBe(new_closed_date);
		});

		test('Delete a Review Set', async () => {
			const problem_set_store = useProblemSetStore();
			const set_to_delete = problem_set_store.findProblemSet({ set_name: 'Review Set #9' });
			const deleted_set = await problem_set_store.deleteProblemSet(set_to_delete as ProblemSet);
			// Check that the deleted_set is the same as the original
			expect(deleted_set.toObject()).toStrictEqual(set_to_delete?.toObject());
			const is_the_set_deleted = problem_set_store.findProblemSet({ set_name: 'Review Set #9' });
			expect(is_the_set_deleted).toBeUndefined();
		});
	});

	let precalc_problems_from_csv: Problem[];

	describe('Fetching UserSets', () => {
		test('Fetching User sets from a course', async () => {
			const problem_set_store = useProblemSetStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			await problem_set_store.fetchUserSets({
				course_id: precalc_course.course_id,
				set_id: hw1?.set_id ?? 0
			});
			expect(problem_set_store.user_sets.length).toBeGreaterThan(0);

			// Setup and load the user sets data from a csv file.
			const user_set_config = {
				params: ['set_dates', 'set_params']
			};
			const user_sets_to_parse = await loadCSV('t/db/sample_data/user_sets.csv', user_set_config);

			// Filter only user sets from Precalculus, set: HW #1
			const user_sets_from_csv = user_sets_to_parse
				.filter(set => set.set_name === 'HW #1' && set.course_name === 'Precalculus')
				.map(set => new UserHomeworkSet(set));
			const user_sets_from_store = problem_set_store.findUserSet({ set_name: 'HW #1' });

			expect(cleanIDs(user_sets_from_store)).toStrictEqual(cleanIDs(user_sets_from_csv));
		});

	});

	describe('CRUD functions on User Homework', () => {
		let new_problem_set: ProblemSet;
		let added_user_set: UserSet;
		test('Add a new User Homework set to a course.', async () => {
			// First, make a new problem set
			const problem_set_store = useProblemSetStore();
			new_problem_set = await problem_set_store.addProblemSet(new HomeworkSet({
				set_name: 'HW #9',
				course_id: precalc_course.course_id
			}));

			// Fetch the users from the course
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			const user = user_store.merged_users[0];

			const user_set = new UserHomeworkSet({
				set_id: new_problem_set.set_id,
				course_user_id: user.course_user_id,
				set_visible: true
			});
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			expect(cleanIDs(added_user_set)).toStrictEqual(cleanIDs(user_set));
		});

		let user_set_to_update: UserSet;
		test('Update a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			user_set_to_update = added_user_set.clone();
			user_set_to_update.set_visible = false;
			const updated_user_set = await problem_set_store.updateUserSet(user_set_to_update);
			expect(cleanIDs(updated_user_set)).toStrictEqual(cleanIDs(user_set_to_update));
		});

		test('Delete a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			const user_set_to_delete = await problem_set_store.deleteUserSet(added_user_set);
			expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(user_set_to_update));

			// Also need to delete the problem set that was created.
			await problem_set_store.deleteProblemSet(new_problem_set);
		});
	});

	describe('CRUD functions on User Quiz', () => {
		let new_quiz: ProblemSet;
		let added_user_set: UserSet;
		test('Add a new User Quiz to a course.', async () => {
			// First, make a new problem set
			const problem_set_store = useProblemSetStore();
			new_quiz = await problem_set_store.addProblemSet(new Quiz({
				set_name: 'Quiz #9',
				course_id: precalc_course.course_id
			}));

			// Fetch the users from the course
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			const user = user_store.merged_users[0];

			const user_set = new UserQuiz({
				set_id: new_quiz.set_id,
				course_user_id: user.course_user_id,
				set_visible: true
			});
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			expect(cleanIDs(added_user_set)).toStrictEqual(cleanIDs(user_set));
		});

		let user_set_to_update: UserSet;
		test('Update a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			user_set_to_update = added_user_set.clone();
			user_set_to_update.set_visible = false;
			const updated_user_set = await problem_set_store.updateUserSet(user_set_to_update);
			expect(cleanIDs(updated_user_set)).toStrictEqual(cleanIDs(user_set_to_update));
		});

		test('Delete a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			const user_set_to_delete = await problem_set_store.deleteUserSet(added_user_set);
			expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(user_set_to_update));

			// Also need to delete the problem set that was created.
			await problem_set_store.deleteProblemSet(new_quiz);
		});
	});

	describe('CRUD functions on User Review Set', () => {
		let new_review_set: ProblemSet;
		let added_user_set: UserSet;
		test('Add a new User Homework set to a course.', async () => {
			// First, make a new problem set
			const problem_set_store = useProblemSetStore();
			new_review_set = await problem_set_store.addProblemSet(new ReviewSet({
				set_name: 'Review #9',
				course_id: precalc_course.course_id
			}));

			// Fetch the users from the course
			const user_store = useUserStore();
			await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
			await user_store.fetchCourseUsers(precalc_course.course_id);
			const user = user_store.merged_users[0];

			const user_set = new UserReviewSet({
				set_id: new_review_set.set_id,
				course_user_id: user.course_user_id,
				set_visible: true
			});
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			expect(cleanIDs(added_user_set)).toStrictEqual(cleanIDs(user_set));
		});

		let user_set_to_update: UserSet;
		test('Update a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			user_set_to_update = added_user_set.clone();
			user_set_to_update.set_visible = false;
			const updated_user_set = await problem_set_store.updateUserSet(user_set_to_update);
			expect(cleanIDs(updated_user_set)).toStrictEqual(cleanIDs(user_set_to_update));
		});

		test('Delete a User Set', async () => {
			const problem_set_store = useProblemSetStore();
			const user_set_to_delete = await problem_set_store.deleteUserSet(added_user_set);
			expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(user_set_to_update));

			// Also need to delete the problem set that was created.
			await problem_set_store.deleteProblemSet(new_review_set);
		});
	});
});

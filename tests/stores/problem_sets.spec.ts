/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// problem_sets.spec.ts
// Test the problem sets Store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import { useProblemSetStore } from 'src/stores/problem_sets';
import { useCourseStore } from 'src/stores/courses';
import { useSessionStore } from 'src/stores/session';
import { api } from 'src/boot/axios';

import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { Course } from 'src/common/models/courses';

import { cleanIDs, loadCSV } from '../utils';

const app = createApp({});

describe('Problem Set store tests', () => {
	let problem_sets_from_csv: ProblemSet[];
	let precalc_course: Course;
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
				set_dates: {
					open: 1000,
					reduced_scoring: 1500,
					due: 2000,
					answer: 3000,
					enable_reduced_scoring: true
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
			problem_set.set_dates.enable_reduced_scoring = false;
			await problem_set_store.updateSet(problem_set);
			const set_to_update = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as HomeworkSet).clone();
			expect(set_to_update?.set_dates.enable_reduced_scoring).toBeFalsy();

			// update the answer date
			set_to_update.set_dates.answer = (set_to_update.set_dates.answer ?? 0) + 100;
			const updated_set = await problem_set_store.updateSet(set_to_update) ?? new ProblemSet();
			expect(cleanIDs(updated_set)).toStrictEqual(cleanIDs(set_to_update));
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
			const quiz_to_update = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as Quiz).clone();
			expect(quiz_to_update?.set_params.timed).toBeFalsy();

			// update the answer date
			quiz_to_update.set_dates.answer = (quiz_to_update.set_dates.answer ?? 0) + 100;
			const updated_quiz = await problem_set_store.updateSet(quiz_to_update);
			expect(updated_quiz).toStrictEqual(quiz_to_update);
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
			const set_to_update = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as ReviewSet).clone();
			expect(set_to_update?.set_params.test_param).toBeFalsy();

			// update the closed date
			set_to_update.set_dates.closed = (set_to_update.set_dates.closed ?? 0) + 100;
			const updated_set = await problem_set_store.updateSet(set_to_update);
			expect(updated_set).toStrictEqual(set_to_update);
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
});

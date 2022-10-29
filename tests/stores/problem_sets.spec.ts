/** @jest-environment jsdom */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// Test the problem sets Store

import { setActivePinia, createPinia } from 'pinia';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import { useProblemSetStore } from 'src/stores/problem_sets';
import { useCourseStore } from 'src/stores/courses';
import { useSessionStore } from 'src/stores/session';

import { HomeworkSet, ProblemSet, Quiz, ReviewSet } from 'src/common/models/problem_sets';
import { Course } from 'src/common/models/courses';

import { cleanIDs } from '../utils';
import { checkPassword } from 'src/common/api-requests/session';

const app = createApp({});

describe('Problem Set store tests', () => {
	const problem_sets_from_json: ProblemSet[] = [];
	let precalc_course: Course;

	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// Login to the course as the admin in order to be authenticated for the rest of the test.
		const session_info = await checkPassword({ username: 'admin', password: 'admin' });
		const session_store = useSessionStore();
		session_store.updateSessionInfo(session_info);
		await session_store.fetchUserCourses();

		(await import('../../t/db/sample_data/hw_sets.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new HomeworkSet(set)));

		(await import('../../t/db/sample_data/quizzes.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new Quiz(set)));

		(await import('../../t/db/sample_data/review_sets.json')).default
			.find((course) => course.course_name === 'Precalculus')
			?.sets.forEach((set) => problem_sets_from_json.push(new ReviewSet(set)));

		// We'll need the courses as well.
		const courses_store = useCourseStore();
		await courses_store.fetchCourses();
		precalc_course = courses_store.courses.find(course => course.course_name === 'Precalculus') as Course;

		// Add the precalc course to the session;
		session_store.setCourse(precalc_course.course_id);
	});

	// sort by set name and clean up the _id tags.
	const sortAndClean = (user_courses: ProblemSet[]) => {
		return cleanIDs(user_courses.sort((a, b) =>
			a.set_name < b.set_name ? -1 : a.set_name > b.set_name ? 1 : 0));
	};

	describe('Fetch problem sets', () => {
		test('Fetch the Problem Sets for a course', async () => {
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course?.course_id ?? 0);
			expect(problem_set_store.problem_sets.length).toBeGreaterThan(0);

			expect(sortAndClean(problem_set_store.problem_sets as ProblemSet[]))
				.toStrictEqual(sortAndClean(problem_sets_from_json));
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

	describe('Test that invalid homework sets are handled correctly', () => {
		test('Try to add an invalid homework set', async () => {
			const problem_set_store = useProblemSetStore();

			// A Homework set needs a not-empty set name.
			const hw = new HomeworkSet({
				set_name: ''
			});
			expect(hw.isValid()).toBe(false);
			await expect(async () => { await problem_set_store.addProblemSet(hw); })
				.rejects.toThrow('The added problem set is invalid');
		});

		test('Try to update an invalid global user', async () => {
			const problem_set_store = useProblemSetStore();
			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			if (hw1) {
				hw1.set_id = 1.34;
				expect(hw1.isValid()).toBe(false);
				await expect(async () => { await problem_set_store.updateSet(hw1 as HomeworkSet); })
					.rejects.toThrow('The updated problem set is invalid');
			} else {
				throw 'This should not have be thrown.  Problem set hw1 is not defined.';
			}
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
					can_retake: true
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
			problem_set.set_params.can_retake = false;
			await problem_set_store.updateSet(problem_set);
			const set_to_update = (problem_set_store.problem_sets
				.find(set => set.set_id === problem_set.set_id) as ReviewSet).clone();
			expect(set_to_update?.set_params.can_retake).toBeFalsy();

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

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
import { loadCSV } from '../utils';
import { parseBoolean, parseNonNegInt } from 'src/common/models/parsers';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useCourseStore } from 'src/stores/courses';
import { Dictionary, generic } from 'src/common/models';
import { Course } from 'src/common/models/courses';
import { ParseableProblem, ParseableSetProblem, ParseableSetProblemParams, parseProblem, Problem, SetProblem } from 'src/common/models/problems';

const app = createApp({});

describe('Problem Set store tests', () => {
	let problem_sets_from_csv: Dictionary<generic>[];
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
		// combine all problem_sets and convert to JS objects
		problem_sets_from_csv = [...hw_sets_from_csv, ...quizzes_from_csv,
			...review_sets_from_csv].map(set => set.toObject()) as Dictionary<generic>[];
		// strip course_id and set_id
		problem_sets_from_csv.forEach(set => {
			delete set.set_id;
			delete set.course_id;
		});

		// We'll need the courses as well.
		const courses_store = useCourseStore();
		await courses_store.fetchCourses();
		precalc_course = courses_store.courses.find(course => course.course_name === 'Precalculus') as Course;
	});

	describe('Fetch problem sets', () => {

		test('Fetch the Problem Sets for a course', async () => {
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course?.course_id ?? 0);
			expect(problem_set_store.problem_sets.length).toBeGreaterThan(0);
			const sets_from_server = problem_set_store.problem_sets.map(set => set.toObject());
			// strip course_id and set_id
			sets_from_server.forEach(set => {
				delete set.set_id;
				delete set.course_id;
			});
			expect(sets_from_server).toStrictEqual(problem_sets_from_csv);
		});

	});

	describe('CRUD test for problem sets', () => {

		test('Add a new set', async () => {
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
			const new_set_retrieved = (problem_set_store.getProblemSet({ set_name: 'HW #9'})
				)?.toObject() as Dictionary<generic>;
			// remove the set_id and set_type to compare to the info submitted.
			delete new_set_retrieved.set_id;
			delete new_set_retrieved.set_type;
			expect(new_set_retrieved).toStrictEqual(new_set_info);

		});

		test('Update a set', async () => {
			const problem_set_store = useProblemSetStore();
			const problem_set = (problem_set_store.getProblemSet({set_name: 'HW #9'}) as HomeworkSet).clone();
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

		test('Delete a problem set', async () => {
			const problem_set_store = useProblemSetStore();
			const set_to_delete = problem_set_store.getProblemSet({ set_name: 'HW #9'});
			const deleted_set = await problem_set_store.deleteProblemSet(set_to_delete as ProblemSet);
			// Check that the deleted_set is the same as the original
			expect(await deleted_set.toObject()).toStrictEqual(set_to_delete?.toObject());
			const is_the_set_deleted = problem_set_store.getProblemSet({ set_name: 'HW #9'});
			expect(is_the_set_deleted).toBeUndefined();
		});
	});

	let precalc_problems: Problem[];

	describe('fetching set problems for a course', () => {
		test.only('fetching problems for a course.', async () => {
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchSetProblems(precalc_course.course_id);
			expect(problem_set_store.set_problems.length).toBeGreaterThan(0);

			const problems_config = {
				params: ['problem_params'],
				non_neg_fields: ['problem_number']
			};

			const problems_to_parse = await loadCSV('t/db/sample_data/problems.csv', problems_config);
			console.log(problems_to_parse);
			// remove any undefined library_ids
			problems_to_parse.forEach(prob => {
				if (!(prob as ParseableSetProblem).problem_params?.library_id) {
					delete (prob?.problem_params as ParseableSetProblemParams).library_id;
				}
			})
			precalc_problems = problems_to_parse.map(prob => parseProblem(prob as ParseableSetProblem,'Set'));
		});
	});
});

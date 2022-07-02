/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// problem_sets.spec.ts
// Test the user sets Store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
import { api } from 'boot/axios';

import { useCourseStore } from 'src/stores/courses';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSessionStore } from 'src/stores/session';
import { useUserStore } from 'src/stores/users';

import { Course } from 'src/common/models/courses';
import {
	ProblemSet, HomeworkSet, Quiz, ReviewSet, ParseableProblemSetDates, ParseableProblemSetParams
} from 'src/common/models/problem_sets';
import { CourseUser } from 'src/common/models/users';
import {
	UserSet, UserHomeworkSet, UserQuiz, UserReviewSet, mergeUserSet, parseDBUserSet, DBUserHomeworkSet
} from 'src/common/models/user_sets';

import { loadCSV, cleanIDs } from '../utils';

const app = createApp({});

describe('Tests user sets and merged user sets in the problem set store', () => {
	let problem_sets_from_csv: ProblemSet[];
	let precalc_user_sets: UserSet[];

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
			param_boolean_fields: ['timed', 'enable_reduced_scoring', 'can_retake'],
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

		// Fetch course users and they are needed below.
		const user_store = useUserStore();
		await user_store.fetchGlobalCourseUsers(precalc_course.course_id);
		await user_store.fetchCourseUsers(precalc_course.course_id);

	});

	describe('Fetching DBUserSets', () => {
		test('Fetching DBUser sets from a course', async () => {
			const problem_set_store = useProblemSetStore();
			await problem_set_store.fetchProblemSets(precalc_course.course_id);
			await problem_set_store.fetchAllUserSets(precalc_course.course_id);
			expect(problem_set_store.user_sets.length).toBeGreaterThan(0);

			// Setup and load the user sets data from a csv file.
			const user_sets_to_parse = await loadCSV('t/db/sample_data/user_sets.csv', {
				params: ['set_dates', 'set_params'],
				boolean_fields: ['set_visible'],
				param_boolean_fields: ['timed', 'enable_reduced_scoring', 'can_retake'],
				param_non_neg_int_fields: ['quiz_duration']
			});

			// Load the users from the CSV file and filter only the Precalc students.
			const users_to_parse = await loadCSV('t/db/sample_data/students.csv', {
				boolean_fields: ['is_admin'],
				non_neg_int_fields: ['user_id']
			});

			const precalc_merged_users = users_to_parse.filter(user => user.course_name === 'Precalculus')
				.map(user => new CourseUser(user));

			// Filter only user sets from HW #1
			const hw1_from_csv = user_sets_to_parse
				.filter(set => set.course_name === 'Precalculus' && set.set_name === 'HW #1')
				.map(set => new DBUserHomeworkSet(set));

			const hw1 = problem_set_store.findProblemSet({ set_name: 'HW #1' });
			const db_user_sets_from_store = problem_set_store.db_user_sets
				.filter(set => set.set_id === hw1?.set_id);
			expect(cleanIDs(db_user_sets_from_store)).toStrictEqual(cleanIDs(hw1_from_csv));

			precalc_user_sets = user_sets_to_parse
				.filter(set => set.course_name === 'Precalculus')
				.map(obj => {
					const problem_set = problem_sets_from_csv.find(set => set.set_name == obj.set_name);
					const merged_user = precalc_merged_users.find(u => u.username === obj.username) ?? new CourseUser();
					const user_set = parseDBUserSet({
						set_type: problem_set?.set_type,
						set_dates: obj.set_dates as ParseableProblemSetDates,
						set_params: obj.set_params as ParseableProblemSetParams
					});
					return mergeUserSet(problem_set as ProblemSet, user_set, merged_user) ?? new UserSet();
				});
		});
	});
	let new_hw_set: ProblemSet;

	describe('CRUD functions on User Homework', () => {
		let added_user_set: UserSet;
		test('Add a new User Homework set to a course.', async () => {
			// First, make a new problem set
			const problem_set_store = useProblemSetStore();
			new_hw_set = await problem_set_store.addProblemSet(new HomeworkSet({
				set_name: 'HW #9',
				course_id: precalc_course.course_id,
			}));

			const user_store = useUserStore();
			const user = user_store.course_users[0];

			const user_set = new UserHomeworkSet({
				username: 'homer',
				set_name: 'HW #9',
				set_id: new_hw_set.set_id,
				course_user_id: user.course_user_id,
				set_visible: true
			});
			expect(user_set.isValid()).toBe(true);
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

		test('Delete a User HW Set', async () => {
			const problem_set_store = useProblemSetStore();
			const user_set_to_delete = await problem_set_store.deleteUserSet(added_user_set);
			if (user_set_to_delete) {
				expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(added_user_set));
			} else {
				test('Object was undefined', done => {
					done.fail(new Error('Object was undefined'));
				});
			}
		});
	});

	describe('Test that invalid user sets are handled correctly', () => {
		test('Try to add an invalid user sets', async () => {
			const problem_set_store = useProblemSetStore();

			// A Homework set needs a not-empty set name.
			const hw = new UserHomeworkSet({
				set_name: ''
			});
			expect(hw.isValid()).toBe(false);
			await expect(async () => { await problem_set_store.addUserSet(hw); })
				.rejects.toThrow('The added user set is invalid');
		});

		test('Try to update an invalid user set', async () => {
			const problem_set_store = useProblemSetStore();
			const hw1 = problem_set_store.findUserSet({ username: 'homer', set_name: 'HW #1' });
			if (hw1) {
				hw1.set_id = 1.34;
				expect(hw1.isValid()).toBe(false);
				await expect(async () => { await problem_set_store.updateUserSet(hw1 as UserHomeworkSet); })
					.rejects.toThrow('The updated user set is invalid');
			} else {
				throw 'This should not have be thrown.  User set hw1 is not defined.';
			}
		});
	});

	let new_quiz: ProblemSet;
	describe('CRUD functions on User Quiz', () => {
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
			const user = user_store.course_users[0];

			const user_set = new UserQuiz({
				set_id: new_quiz.set_id,
				course_user_id: user.course_user_id,
				set_visible: true,
				set_name: new_quiz.set_name,
				username: 'homer'
			});
			added_user_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			expect(cleanIDs(added_user_set)).toStrictEqual(cleanIDs(user_set));
		});

		let user_set_to_update: UserSet;
		test('Update a User Quiz', async () => {
			const problem_set_store = useProblemSetStore();
			user_set_to_update = added_user_set.clone();
			user_set_to_update.set_visible = false;
			const updated_user_set = await problem_set_store.updateUserSet(user_set_to_update);
			expect(cleanIDs(updated_user_set)).toStrictEqual(cleanIDs(user_set_to_update));
		});

		test('Delete a User Quiz', async () => {
			const problem_set_store = useProblemSetStore();
			const user_set_to_delete = await problem_set_store.deleteUserSet(user_set_to_update);
			if (user_set_to_delete) {
				expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(user_set_to_update));
			} else {
				test('Object was undefined', done => {
					done.fail(new Error('Object was undefined'));
				});
			}
		});
	});

	let new_review_set: ProblemSet;
	describe('CRUD functions on User Review Set', () => {
		let added_user_review_set: UserSet;
		test('Add a new User Review Set to a course.', async () => {
			// First, make a new problem set
			const problem_set_store = useProblemSetStore();
			new_review_set = await problem_set_store.addProblemSet(new ReviewSet({
				set_name: 'Review #9',
				course_id: precalc_course.course_id
			}));

			// Fetch the users from the course
			const user_store = useUserStore();
			const user = user_store.course_users[0];

			const user_set = new UserReviewSet({
				set_id: new_review_set.set_id,
				course_user_id: user.course_user_id,
				set_visible: true,
				set_name: new_review_set.set_name,
				username: 'homer'
			});
			added_user_review_set = await problem_set_store.addUserSet(user_set) ?? new UserSet();
			expect(cleanIDs(added_user_review_set)).toStrictEqual(cleanIDs(user_set));
		});

		let user_review_set_to_update: UserSet;
		test('Update a User Review Set', async () => {
			const problem_set_store = useProblemSetStore();
			user_review_set_to_update = added_user_review_set.clone();
			user_review_set_to_update.set_visible = false;
			const updated_user_set = await problem_set_store.updateUserSet(user_review_set_to_update);
			expect(cleanIDs(updated_user_set)).toStrictEqual(cleanIDs(user_review_set_to_update));
		});

		test('Delete a User Review Set', async () => {
			const problem_set_store = useProblemSetStore();
			const num_user_sets = problem_set_store.user_sets.length;
			const user_set_to_delete = await problem_set_store.deleteUserSet(user_review_set_to_update);

			if (user_set_to_delete) {
				expect(cleanIDs(user_set_to_delete)).toStrictEqual(cleanIDs(user_review_set_to_update));
			} else {
				test('Object was undefined', done => {
					done.fail(new Error('Object was undefined'));
				});
			}

			expect(problem_set_store.user_sets).toHaveLength(num_user_sets - 1);
		});

		afterAll(async () => {
			const problem_set_store = useProblemSetStore();
			// Also need to delete the new problem sets that wer created.
			await problem_set_store.deleteProblemSet(new_hw_set);
			await problem_set_store.deleteProblemSet(new_quiz);
			await problem_set_store.deleteProblemSet(new_review_set);
		});
	});

	let new_user_hw: UserHomeworkSet;
	describe('Test merged user sets', () => {
		test('Test all merged user sets', () => {
			const problem_set_store = useProblemSetStore();
			expect(cleanIDs(precalc_user_sets)).toStrictEqual(cleanIDs(problem_set_store.user_sets));
		});

		test('Add a user set and test that the overrides work.', async () => {
			const problem_set_store = useProblemSetStore();
			const user_store = useUserStore();
			const user_to_assign = user_store.course_users[0];

			// Make a new Problem Set
			new_hw_set = await problem_set_store.addProblemSet(new HomeworkSet({
				set_name: 'HW #99',
				course_id: precalc_course.course_id,
				set_dates: {
					open: 1000,
					reduced_scoring: 1100,
					due: 1500,
					answer: 2000,
					enable_reduced_scoring: true
				}
			}));

			// Add a User set
			new_user_hw = new UserHomeworkSet({
				username: 'homer',
				set_name: new_hw_set.set_name,
				set_id: new_hw_set.set_id,
				course_user_id: user_to_assign.course_user_id,
				set_visible: false,
				set_dates: {
					open: 1200,
					reduced_scoring: 1500,
					due: 2000,
					answer: 2200,
					enable_reduced_scoring: true
				}
			});
			const new_user_set = await problem_set_store.addUserSet(new_user_hw) ?? new UserSet();
			const merged_hw = new UserHomeworkSet({
				user_id: user_to_assign.user_id,
				user_set_id: new_user_set.user_set_id,
				set_id: new_user_set.set_id,
				course_user_id: user_to_assign.course_user_id,
				set_version: new_user_set.set_version,
				set_visible: new_user_hw.set_visible,
				set_name: new_hw_set.set_name,
				username: user_to_assign.username,
				set_type: new_user_set.set_type,
				set_params: new_user_hw.set_params.toObject(),
				set_dates: new_user_hw.set_dates.toObject()
			});

			expect(new_user_hw).toStrictEqual(new_user_set);

			const merged_user_set = mergeUserSet(new_hw_set,
				new DBUserHomeworkSet(new_user_set.toObject()), user_to_assign);

			// Copy over the user_set_id from the database object to one in merged_hw.
			merged_hw.user_set_id = merged_user_set?.user_set_id ?? 0;
			expect(merged_user_set).toStrictEqual(merged_hw);
		});
	});

	// Cleanup some created sets to leave the database in the same state as before the test.
	afterAll(async () => {
		const problem_set_store = useProblemSetStore();
		// delete the newly made problem set:
		await problem_set_store.deleteProblemSet(new_hw_set);
	});
});

/**
 * @jest-environment jsdom
 */
// The above is needed because the logger uses the window object, which is only present
// when using the jsdom environment.

import { HomeworkSet, HomeworkSetDates, HomeworkSetParams, ProblemSet } from 'src/common/models/problem_sets';

describe('Tests for Homework Sets', () => {

	const default_homework_set = {
		set_dates: {
			answer: 0,
			reduced_scoring: 0,
			due: 0,
			open: 0,
			enable_reduced_scoring: false
		},
		set_params: {
			hide_hint: false,
			hardcopy_header: '',
			set_header: '',
			description: ''
		},
		set_id: 0,
		course_id: 0,
		set_name: '',
		set_visible: false,
		set_type: 'HW'
	};

	describe('Create new homework sets', () => {
		test('Test default Homework Set', () => {
			const set = new HomeworkSet();
			expect(set).toBeInstanceOf(HomeworkSet);
			expect(set.toObject()).toStrictEqual(default_homework_set);
		});

		test('Build a HomeworkSet', () => {
			const set = new HomeworkSet();
			expect(set.set_type).toBe('HW');
			expect(set).toBeInstanceOf(HomeworkSet);
			expect(set).toBeInstanceOf(ProblemSet);
			const set1 = new HomeworkSet({ set_name: 'HW 1', set_visible: true });
			expect(set1).toBeInstanceOf(HomeworkSet);
			expect(set1.set_visible).toBe(true);

			const set2 = new HomeworkSet({
				course_id:4,
				set_dates: {
					answer: 1613951940,
					due: 1612137540,
					open: 1609545540,
					reduced_scoring: 1610323140,
					enable_reduced_scoring: true
				},
				set_id: 7,
				set_name: 'HW #1',
				set_params: {
					hide_hint: true
				},
				set_visible: true
			});
			const params = {
				course_id: 4,
				set_dates: {
					answer: 1613951940,
					due: 1612137540,
					open: 1609545540,
					reduced_scoring: 1610323140,
					enable_reduced_scoring: true
				},
				set_id: 7,
				set_name: 'HW #1',
				set_params: {
					hide_hint: true,
					description: '',
					hardcopy_header: '',
					set_header: ''
				},
				set_type: 'HW',
				set_visible: true
			};
			expect(set2.toObject()).toStrictEqual(params);

		});

		test('Check that calling all_fields() and params() is correct', () => {
			const hw_fields = ['set_id', 'set_name', 'course_id', 'set_type', 'set_visible',
				'set_params', 'set_dates'];
			const hw = new HomeworkSet();

			expect(hw.all_field_names.sort()).toStrictEqual(hw_fields.sort());
			expect(hw.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);
			expect(HomeworkSet.ALL_FIELDS.sort()).toStrictEqual(hw_fields.sort());
		});

		test('Clone a HomeworkSet', () => {
			const hw = new HomeworkSet();
			expect(hw.clone().toObject()).toStrictEqual(default_homework_set);
			expect(hw.clone()).toBeInstanceOf(HomeworkSet);
		});
	});

	describe('Set homework fields', () => {
		test('Check for setting fields directly', () => {
			const hw = new HomeworkSet();
			expect(hw.set_type).toBe('HW');

			hw.set_id = 5;
			expect(hw.set_id).toBe(5);

			hw.set_name = 'HW #1';
			expect(hw.set_name).toBe('HW #1');

			hw.course_id = 11;
			expect(hw.course_id).toBe(11);

			hw.set_visible = false;
			expect(hw.set_visible).toBe(false);
		});

		test('Check for setting fields using the set method', () => {
			const hw = new HomeworkSet();

			hw.set({ set_id: 5 });
			expect(hw.set_id).toBe(5);

			hw.set({ set_name: 'HW #1' });
			expect(hw.set_name).toBe('HW #1');

			hw.set({ course_id: 11 });
			expect(hw.course_id).toBe(11);

			hw.set({ set_visible:  false });
			expect(hw.set_visible).toBe(false);
		});

		test('Test the validity of a HomeworkSet', () => {
			let hw = new HomeworkSet();
			// A default homework set is missing a set_name.
			expect(hw.isValid()).toBe(false);

			hw = new HomeworkSet({ set_name: 'HW #1' });
			expect(hw.isValid()).toBe(true);

			hw = new HomeworkSet({ set_name: 'HW #1', set_id: 2.34 });
			expect(hw.isValid()).toBe(false);

			hw = new HomeworkSet({ set_name: 'HW #1', course_id: -32 });
			expect(hw.isValid()).toBe(false);
		});
	});

	describe('Test setting homework set dates.', () => {
		test('Test the default homework set dates', () => {
			const set_dates = new HomeworkSetDates();
			expect(set_dates.toObject()).toStrictEqual(default_homework_set.set_dates);
			expect(set_dates.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const hw_date_fields = ['open', 'reduced_scoring', 'due', 'answer', 'enable_reduced_scoring'];
			const hw_dates = new HomeworkSetDates();

			expect(hw_dates.all_field_names.sort()).toStrictEqual(hw_date_fields.sort());
			expect(hw_dates.param_fields).toStrictEqual([]);
			expect(HomeworkSetDates.ALL_FIELDS.sort()).toStrictEqual(hw_date_fields.sort());
		});

		test('Check that cloning homework set dates works', () => {
			const hw_dates = new HomeworkSetDates();
			expect(hw_dates.clone().toObject()).toStrictEqual(default_homework_set.set_dates);
			expect(hw_dates.clone()).toBeInstanceOf(HomeworkSetDates);
		});
	});

	describe('Check setting homework set dates', () => {
		test('Set homework set dates directly', () => {
			const hw_dates = new HomeworkSetDates();
			hw_dates.open = 100;
			expect(hw_dates.open).toBe(100);

			hw_dates.reduced_scoring = 200;
			expect(hw_dates.reduced_scoring).toBe(200);

			hw_dates.due = 300;
			expect(hw_dates.due).toBe(300);

			hw_dates.answer = 400;
			expect(hw_dates.answer).toBe(400);

			hw_dates.enable_reduced_scoring = true;
			expect(hw_dates.enable_reduced_scoring).toBe(true);
		});

		test('Set homework set dates using the set method', () => {
			const hw_dates = new HomeworkSetDates();
			hw_dates.set({ open: 100 });
			expect(hw_dates.open).toBe(100);

			hw_dates.set({ reduced_scoring: 200 });
			expect(hw_dates.reduced_scoring).toBe(200);

			hw_dates.set({ due: 300 });
			expect(hw_dates.due).toBe(300);

			hw_dates.set({ answer: 400 });
			expect(hw_dates.answer).toBe(400);

			hw_dates.set({ enable_reduced_scoring: true });
			expect(hw_dates.enable_reduced_scoring).toBe(true);
		});

		test('Test for valid and invalid dates', () => {
			const set = new HomeworkSet();
			set.set_dates.set({
				open: 0,
				reduced_scoring: 10,
				due: 10,
				answer: 20
			});
			expect(set.set_dates.isValid()).toBe(true);

			set.set_dates.set({
				open: 0,
				reduced_scoring: 30,
				due: 10,
				answer: 20,
				enable_reduced_scoring: true
			});
			expect(set.set_dates.isValid()).toBe(false);

			set.set_dates.set({
				open: 0,
				reduced_scoring: 10,
				due: 20,
				answer: 15
			});
			expect(set.set_dates.isValid()).toBe(false);

			set.set_dates.enable_reduced_scoring = false;
			expect(set.set_dates.enable_reduced_scoring).toBe(false);

			set.set_dates.set({
				open: 30,
				reduced_scoring: 0,
				due: 40,
				answer: 50
			});
			expect(set.set_dates.isValid()).toBe(true);
		});
	});

	describe('Test setting homework set params.', () => {
		test('Test the default homework set params', () => {
			const set_params = new HomeworkSetParams();
			expect(set_params.toObject()).toStrictEqual(default_homework_set.set_params);
			expect(set_params.isValid()).toBe(true);
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const hw_params_fields = ['hide_hint', 'hardcopy_header', 'set_header', 'description'];
			const hw_params = new HomeworkSetParams();

			expect(hw_params.all_field_names.sort()).toStrictEqual(hw_params_fields.sort());
			expect(hw_params.param_fields).toStrictEqual([]);
			expect(HomeworkSetParams.ALL_FIELDS.sort()).toStrictEqual(hw_params_fields.sort());
		});

		test('Check that cloning homework set dates works', () => {
			const hw_params = new HomeworkSetParams();
			expect(hw_params.clone().toObject()).toStrictEqual(default_homework_set.set_params);
			expect(hw_params.clone()).toBeInstanceOf(HomeworkSetParams);
		});
	});

	describe('Check setting homework set params', () => {
		test('Set homework set params directly', () => {
			const hw_params = new HomeworkSetParams();
			hw_params.hide_hint = true;
			expect(hw_params.hide_hint).toBe(true);

			hw_params.hardcopy_header = 'my header';
			expect(hw_params.hardcopy_header).toBe('my header');

			hw_params.set_header = 'my set header';
			expect(hw_params.set_header).toBe('my set header');

			hw_params.description = 'the description';
			expect(hw_params.description).toBe('the description');
		});

		test('Set homework set params using the set method', () => {
			const hw_params = new HomeworkSetParams();
			hw_params.set({ hide_hint: true });
			expect(hw_params.hide_hint).toBe(true);

			hw_params.set({ hardcopy_header: 'my header' });
			expect(hw_params.hardcopy_header).toBe('my header');

			hw_params.set({ set_header: 'my set header' });
			expect(hw_params.set_header).toBe('my set header');

			hw_params.set({ description: 'the description' });
			expect(hw_params.description).toBe('the description');
		});

		// No tests for validity for this currently because there is nothing
		// check.  If the HomeworkSetParams are updated to include checking for validity
		// then another test should be included.
	});
});

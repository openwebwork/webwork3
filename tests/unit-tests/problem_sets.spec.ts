import { ProblemSet } from 'src/common/models/problem_sets';

describe('Test generic ProblemSets', () => {
	const default_problem_set = {
		set_id: 0,
		set_name: 'set #1',
		course_id: 0,
		set_type: 'UNKNOWN',
		set_params: {},
		set_dates: {}
	}

	describe('Creation of a ProblemSet', () => {
		test('Create a valid ProblemSet', () => {
			const set = new ProblemSet();
			expect(set).toBeInstanceOf(ProblemSet);
		});

		test('Ensure that there are overrides', () => {
			const set = new ProblemSet();
			expect(() => {set.set_params;}).toThrowError('The subclass must override set_params()');
			expect(() => {set.set_dates; }).toThrowError('The subclass must override set_dates()');
			expect(() => {set.hasValidDates(); }).toThrowError('The hasValidDates() method must be overridden.');
			expect(() => {set.isValid(); }).toThrowError('The isValid() method must be overridden.');
			expect(() => {set.clone(); }).toThrowError('The clone method must be overridden in a subclass.');
		});
	});


	describe('Check setting generic fields', () => {
		test('Check that all fields can be set directly', () => {
			const set = new ProblemSet();
			set.set_id = 5;
			expect(set.set_id).toBe(5);

			set.course_id = 10;
			expect(set.course_id).toBe(10);

			set.set_visible = true;
			expect(set.set_visible).toBe(true);

			set.set_name = 'Set #1';
			expect(set.set_name).toBe('Set #1');
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const set_fields = ['set_id', 'set_visible', 'course_id', 'set_type',
				'set_name', 'set_params', 'set_dates'];
			const problem_set = new ProblemSet();

			expect(problem_set.all_field_names.sort()).toStrictEqual(set_fields.sort());
			expect(problem_set.param_fields.sort()).toStrictEqual(['set_dates', 'set_params']);
			expect(ProblemSet.ALL_FIELDS.sort()).toStrictEqual(set_fields.sort());

		});


		test('Check that all fields can be set using the set() method', () => {
			const set = new ProblemSet();
			set.set({set_id: 5});
			expect(set.set_id).toBe(5);

			set.set({course_id: 10});
			expect(set.course_id).toBe(10);

			set.set({set_visible: true});
			expect(set.set_visible).toBe(true);

			set.set({set_name: 'Set #1'});
			expect(set.set_name).toBe('Set #1');
		});
	});
});

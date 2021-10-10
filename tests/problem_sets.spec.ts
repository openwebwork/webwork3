//FizzBuzz.test.ts
/// <reference types="jest" />

import { HomeworkSet, ProblemSet } from '@/store/models/problem_sets';
import { ParseError } from '@/store/models';

test('Build a HomeworkSet', () => {
	const set = new HomeworkSet();
	expect(set instanceof HomeworkSet).toBe(true);
	expect(set instanceof ProblemSet).toBe(true);
	const set1 = new HomeworkSet({ set_name: 'HW 1', set_visible: 0 });
	expect(set1 instanceof HomeworkSet).toBe(true);
	expect(set1.set_visible).toBe(false);

});

test('Test that parsing fields is working', () => {
	const t1 = () => {
		const set1 = new HomeworkSet({ set_id: -1 });
	};
	expect(t1).toThrow(ParseError);
	const set2 =  new HomeworkSet({ set_visible: 1 });
	expect(set2.set_visible).toBe(true);
});

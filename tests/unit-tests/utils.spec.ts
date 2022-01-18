// This tests the lodash function replacments in /src/common/utils.ts

import { pick, mapValues, invert, pickBy } from 'src/common/utils';

test('testing pick', () => {
	const obj = { a: 1, b: 2, c: 3, d: 4 };

	expect(pick(obj, ['a', 'b', 'c', 'd'])).toStrictEqual(obj);
	expect(pick(obj, ['a', 'c'])).toStrictEqual({ a: 1, c: 3 });
	expect(pick(obj, ['a', 'b', 'd', 'e'])).toStrictEqual({ a: 1, b: 2, d: 4 });

});

test('testing mapValues', () => {
	const obj = { a: 1, b: 2, c: 3, d: 4 };
	expect(mapValues(obj, (x: number) => x + 1)).toStrictEqual({
		a: 2, b: 3, c: 4, d: 5
	});
	expect(mapValues(obj, (x: number) => Math.pow(x, 2))).toStrictEqual({
		a: 1, b: 4, c: 9, d: 16
	});

	const obj2 = {
		apples: { category: 'produce', quantity: 3 },
		hot_dots: { category: 'deli', quantity: 5 },
		ice_cream: { category: 'frozen', quantity: 10 }
	};

	expect(mapValues(obj2, food => food.category)).toStrictEqual({
		apples: 'produce',
		hot_dots: 'deli',
		ice_cream: 'frozen'
	});

});

test('testing invert', () => {
	const obj = { a: '1', b: '2', c: '3', d: '4' };
	expect(invert(obj)).toStrictEqual({
		'1': 'a', '2': 'b', '3': 'c', '4': 'd'
	});
});

test('testing pickBy', () => {
	const obj = { a: 1, b: '2', c: 3 };
	expect(pickBy(obj, (v: number | string) => typeof v === 'number'))
		.toStrictEqual({ a: 1, c: 3 });

	const obj2 = {
		key1: 'apple',
		key2: 'banana',
		key3: 'art history',
	};

	expect(pickBy(obj2, (v: string) => /^a/.test(v)))
		.toStrictEqual({ key1: 'apple', key3: 'art history' });

});

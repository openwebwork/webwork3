// This tests the lodash function replacments in /src/common/utils.ts

import { pick, mapValues, invert, pickBy, random } from 'src/common/utils';

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

test('testing random', () => {
	// test 1000 random numbers between 5 and 10.
	// should return numbers in 5,6,7,8,9
	const arr = [];
	for (let i = 0; i < 1000; i++) {
		arr[i] = random(5, 10);
	}

	expect(arr.filter(v => v >= 5 && v <= 10).length).toBe(1000);
	expect(arr.filter(v => v == 5).length).toBeGreaterThan(0);
	expect(arr.filter(v => v == 10).length).toBe(0);

	// test 1000 random numbers between 5.5 and 10.5.
	// should returns numbers in 6,7,8,9 only.
	const arr2 = [];
	for (let i = 0; i < 100; i++) {
		arr2[i] = random(5.5, 10.5);
	}

	expect(arr2.filter(v => v >= 5 && v <= 10).length).toBe(100);
	expect(arr2.filter(v => v == 5).length).toBe(0);
	expect(arr2.filter(v => v == 10).length).toBe(0);

});

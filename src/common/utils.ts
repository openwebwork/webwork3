// These are a set of functions to replace equivalents in lodash.

/**
 * This returns an object formed by the passed in object and only the selected
 * keys.
 *
 * Example:
 *
 * const obj = {a: 1, b: 2, c: 3, d: 4}
 * pick(obj, ['a', 'c']) returns {a: 1, c: 3}
 */

export const pick = <T>(object: { [key: string]: T }, keys: Array<string>): { [key: string]: T } => {
	return keys.reduce((obj: { [key: string]: T }, key: string) => {
		if (object && Object.prototype.hasOwnProperty.call(object, key)) {
			obj[key] = object[key];
		}
		return obj;
	}, {});
};

/**
 * This function returns an object where a function mapper is applied to get value of the input object.
 *
 * Examples:
 * const obj = { a: 1, b: 2, c: 3, d: 4 };
 * mapValues(obj, (x: number) => x + 1) returns { a: 2, b: 3, c: 4, d: 5 }
 *
 * This can include nested objects:
 * const obj2 = {
 *    apples: { category: 'produce', quantity: 3 },
 *    hot_dots: { category: 'deli', quantity: 5 },
 *    ice_cream: { category: 'frozen', quantity: 10 }
 * };
 * mapValues(obj2, food => food.category))
 * returns
 * { apples: 'produce', hot_dogs: 'deli', ice_cream: 'frozen' }
 */

export const mapValues = <T, S>(object: { [key: string]: T }, mapper: (key: T) => S): { [key: string]: S } => {
	return Object.entries(object).reduce((ret: { [key: string]: S }, [key, obj]) => {
		ret[key] = mapper(obj);
		return ret;
	}, {});
};

/**
 *  Inverts the input object's keys and values.
 *
 *  invert({ a: '1', b: '2', c: '3', d: '4' })
 *  returns
 *  {'1': 'a', '2': 'b', '3': 'c', '4': 'd'}
 */

export const invert = (object: { [key: string]: string }) => {
	return Object.entries(object).reduce((acc, [key, value]) => ({ ...acc, [value]: key }), {});
};

/**
 * This returns a object from the input object in which the keys satisfy the check condition.
 *
 * Example:
 * const obj2 = {
 *  key1: 'apple',
 *  key2: 'banana',
 *  key3: 'art history',
 * };
 * pickBy(obj2, (v) => /^a/.test(v))
 * returns
 * {key1: 'apple', key3: 'art history'}
 */

export const pickBy = <T>(object: { [key: string]: T }, check: (value: T) => boolean) => {
	const obj: { [key: string]: T } = {};
	for (const [key, value] of Object.entries(object)) {
		if (check(value)) {
			obj[key] = object[key];
		}
	}
	return obj;
};

/**
 * This returns a random integer between ceil(min) and floor(max).
 *
 * For example, random(5, 10) returns one of 5, 6, 7, 8, 9
 */

export const random = (min: number, max: number) => {
	min = Math.ceil(min);
	max = Math.floor(max);
	return Math.floor(Math.random() * (max - min) + min);
};

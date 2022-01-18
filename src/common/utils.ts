// These are a set of functions to replace equivalents in lodash.

/**
 * This returns an object formed by the passed in object and only the selected
 * keys.
 *
 *
 * @param object: An object in the form { [key: string]: T }
 * @param keys: The keys of the object to be returned as an array of strings.
 * @returns an object with only those selected keys.
 *
 * Example:
 *
 * const obj = {a: 1, b: 2, c: 3, d: 4}
 * pick(obj,['a', 'c']) returns {a: 1, c: 3}
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
 * @param object:  An object in the form { [key: string]: T }
 * @param mapper: A function to be applied to each value in object.
 * @returns an object with the same keys as the input object and where mapper has been applied to each value.
 *
 * const obj = { a: 1, b: 2, c: 3, d: 4 };
 * mapValues(obj, (x: number) => x + 1) returns { a: 2, b: 3, c: 4, d: 5 }
 *
 *
 */

export const mapValues = <T, S>(object: { [key: string]: T }, mapper: (key: T) => S): { [key: string]: S} => {
	return Object.entries(object).reduce((ret: { [key: string]: S }, [key, obj]) => {
		ret[key] = mapper(obj);
		return ret;
	}, {});
};

/**
 *  Inverts the input object's keys and values.
 *
 * @param object Object of the form: { [key: string]: string }
 * @returns the object where the key and value has been swapped.
 *
 *
 */

export const invert = (object: { [key: string]: string }) => {
	return Object.entries(object).reduce((acc, [key, value]) => ({ ...acc, [value]: key }), {});
};

/**
 * This returns a object from the input object in which the keys satisfy the check condition.
 *
 * @param object  An object in the form { [key: string]: T }
 * @param check A function where true values are to be in the return object.
 * @returns an object on only the key/value pairs where check is true.
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

export const random = (max: number, min: number) => {
	min = Math.ceil(min);
	max = Math.floor(max);
	return Math.floor(Math.random() * (max - min) + min);
};

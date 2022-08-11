/**
 * This module contains all parsing functions and needed regular expressions
 * for all of webwork3.
 */

/**
 * ParseError is a general Error class for any parsing errors.
 */
export class ParseError extends Error {
	type: string;
	message: string;
	field?: string;
	constructor(type: string, message: string, field?: string) {
		super();
		this.type = type;
		this.message = message;
		if (field != undefined) this.field = field;
	}
}

/**
 * A MergeError class is a general error class for handling merge errors.
 */
export class MergeError extends Error {
	constructor(str: string) {
		super(str);
	}
};

/**
 * NonNegIntException is thrown when the input is not an nonnegative integer.
 */
export class NonNegIntException extends ParseError {
	constructor(message: string) {
		super('NonNegIntException', message);
	}
}

/**
 * UsernameParseException is thrown when the input is not an valid username.
 */
export class UsernameParseException extends ParseError {
	constructor(message: string) {
		super('UsernameParseExcpeption', message, 'username');
	}
}

/**
 * EmailParseException is thrown when the input is not an valid email address.
 */
export class EmailParseException extends ParseError {
	constructor(message: string) {
		super('EmailParseException', message, 'email');
	}
}

/**
 * NonNegDecimalException is thrown when the input is not an nonnegative decimal.
 */
export class NonNegDecimalException extends ParseError {
	constructor(message: string) {
		super('NonNegDecimalException', message);
	}
}

/**
 * BooleanParseException is thrown when the input is not a valid boolean
 * including perl boolean (0, 1) and the strings 'true' and 'false'.
 */
export class BooleanParseException extends ParseError {
	constructor(message: string) {
		super('BooleanParseException', message);
	}
}

/**
 * NumberParseException is thrown when the input is not a number.
 */
export class NumberParseException extends ParseError {
	constructor(message: string) {
		super('NumberParseException', message);
	}
}

/**
 * StringParseException is thrown when the input is not a string.
 */
export class StringParseException extends ParseError {
	constructor(message: string) {
		super('StringParseException', message);
	}
}

// Parsing functions

export const non_neg_int_re = /^\s*(\d+)\s*$/;
export const non_neg_decimal_re = /(^\s*(\d+)(\.\d*)?\s*$)|(^\s*\.\d+\s*$)/;
export const mail_re = /^[\w.]+@([a-zA-Z_.]+)+\.[a-zA-Z]{2,9}$/;
export const username_re = /^[_a-zA-Z]([a-zA-Z._0-9])+$/;
export const time_re = /^([01][0-9]|2[0-3]):[0-5]\d$/;
// Update this for localization
// This a regexp for time durations separated by commas.
export const time_duration_re = /^(((\d+)\s(sec|second|min|minute|day|week|hr|hour)s?),?\s?)+$/i;

// Checking functions

export const isNonNegInt = (v: number | string) => non_neg_int_re.test(`${v}`);
export const isNonNegDecimal = (v: number | string) => non_neg_decimal_re.test(`${v}`);
export const isValidUsername = (v: string) => username_re.test(v) || mail_re.test(v);
export const isValidEmail = (v: string) => mail_re.test(v);
export const isTimeDuration = (v: string) => time_duration_re.test(v);
export const isTime = (v: string) => time_re.test(v);

// Parsing functions

export function parseNonNegInt(val: string | number) {
	if (isNonNegInt(val)) return parseInt(`${val}`);
	throw new NonNegIntException(`The value ${val} is not a non-negative integer`);
}

export function parseNonNegDecimal(val: string | number) {
	if (isNonNegDecimal(val)) return parseFloat(`${val}`);
	throw new NonNegDecimalException(`The value ${val} is not a non-negative decimal`);
}

export function parseUsername(val: string) {
	if (isValidUsername(val)) return val;
	throw new UsernameParseException(`The value '${val?.toString() ?? ''}' is not a value username`);
}

export function parseEmail(val: string) {
	if (isValidEmail(val)) return val;
	throw new EmailParseException(`The value '${val?.toString() ?? ''}' is not a value email`);
}

const booleanRE = /^([01])|(true)|(false)$/;
const booleanTrue = /^(1)|(true)$/;

export function parseBoolean(_value: boolean | string | number) {
	if (typeof _value === 'boolean') return _value;
	if (typeof _value === 'number' && (_value === 1 || _value === 0)) {
		return _value === 1;
	}
	if (typeof _value === 'string' && booleanRE.test(_value)) {
		return booleanTrue.test(_value);
	}
	throw new BooleanParseException(`The value '${_value}' is not a boolean`);
}

export function parseNumber(_value: string | number) {
	if (typeof _value === 'number') {
		return _value;
	} else if (typeof _value === 'string' && /^-?\d+(\.\d+)?|-?\.\d+$/.test(_value)) {
		return parseFloat(_value);
	}
	throw new NumberParseException(`The value '${_value}' is not a number.`);
}

export function parseString(_value: string | number | boolean) {
	if (typeof _value !== 'string') {
		throw new StringParseException(`The value '${_value.toString()}' is not a string.`);
	} else {
		return _value;
	}
}

/**
 * Converts a time_duration type setting to a human-readable one.
 * TODO: use localization for this.
 * @params td - time duration in seconds.
 */

export const humanReadableTimeDuration = (td: number): string => {
	const times = {
		week: Math.floor(td / 604800),
		day: Math.floor(td % 604800 / 86400),
		hour: Math.floor(td % 86400 / 3600),
		min: Math.floor(td % 3600 / 60),
		sec: td % 60
	};

	return Object.entries(times).reduce((prev: string, [key, value]) => prev +
		// if the time value is non zero, and there is already something in prev, add a comma
		(prev != '' && value > 0 ? ', ' : '') +
		// pluralize.
		(value > 0 ? `${value} ${key}${value === 1 ? '' : 's'}` : ''), '');
};

/**
 * Convert a time_duration as a string (possibility separated by commas) to a number of seconds.
 */

export const convertTimeDuration = (dur: string): number => {
	const times = dur.split(/,\s/);
	let time_duration = 0;
	times.forEach(t => {
		const match_sec = /^(\d+)\s(sec(ond)?)s?$/.exec(t);
		const match_min = /^(\d+)\s(min(ute)?)s?$/.exec(t);
		const match_hr = /^(\d+)\s(h(ou)?r)s?$/.exec(t);
		const match_day = /^(\d+)\s(day)s?$/.exec(t);
		const match_week = /^(\d+)\s(week)s?$/.exec(t);
		if (match_sec) {
			time_duration += parseInt(match_sec[0]);
		} else if (match_min) {
			time_duration += parseInt(match_min[0]) * 60;
		} else if (match_hr) {
			time_duration += parseInt(match_hr[0]) * 3600;
		} else if (match_day) {
			time_duration += parseInt(match_day[0]) * 86400;
		} else if (match_week) {
			time_duration += parseInt(match_week[0]) * 604800;
		}
	});
	return time_duration;
};

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

/**
 * UserRoleException is thrown when the input is not a valid UserRole
 */

export class UserRoleException extends ParseError {
	constructor(message: string) {
		super('UserRoleException', message, 'role');
	}
}

// Parsing functions

export function parseNonNegInt(val: string | number) {
	if (/^\s*(\d+)\s*$/.test(`${val}`)) {
		return parseInt(`${val}`);
	} else {
		throw new NonNegIntException(`The value ${val} is not a non-negative integer`);
	}
}

export function parseNonNegDecimal(val: string | number) {
	if (/(^\s*(\d+)(\.\d*)?\s*$)|(^\s*\.\d+\s*$)/.test(`${val}`)) {
		return parseFloat(`${val}`);
	} else {
		throw new NonNegDecimalException(`The value ${val} is not a non-negative decimal`);
	}
}

export const mailRE = /^[\w.]+@([a-zA-Z_.]+)+\.[a-zA-Z]{2,9}$/;
export const usernameRE = /^[_a-zA-Z]([a-zA-Z._0-9])+$/;

export function parseUsername(val: string | undefined) {
	if (typeof val === 'string' && (val === '' || mailRE.test(`${val ?? ''}`) || usernameRE.test(`${val}`))) {
		return val;
	} else {
		throw new UsernameParseException(`The value '${val?.toString() ?? ''}' is not a value username`);
	}
}

export function parseEmail(val: string | undefined) {
	if (typeof val === 'string' && mailRE.test(`${val}`)) {
		return val;
	} else {
		throw new EmailParseException(`The value '${val?.toString() ?? ''}' is not a value email`);
	}
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

export enum UserRole {
	admin = 'ADMIN',
	instructor = 'INSTRUCTOR',
	ta = 'TA',
	student = 'STUDENT',
	unknown = 'UNKNOWN'
}

export function parseUserRole(role: string): UserRole {
	if (role.toLocaleLowerCase() === 'admin') return UserRole.admin;
	if (role.toLocaleLowerCase() === 'instructor') return UserRole.instructor;
	if (role.toLocaleLowerCase() === 'ta') return UserRole.ta;
	if (role.toLocaleLowerCase() === 'student') return UserRole.student;
	throw new UserRoleException(`The value '${role}' is not a valid role.`);
}

export function parseString(_value: string | number | boolean) {
	if (typeof _value !== 'string') {
		throw new StringParseException(`The value '${_value.toString()}' is not a string.`);
	} else {
		return _value;
	}
}

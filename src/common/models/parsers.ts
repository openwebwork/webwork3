// General Parsing error

export class ParseError {
	type: string;
	message: string;
	field?: string;
	constructor(type: string, message: string, field?: string) {
		this.type = type;
		this.message = message;
		if (field != undefined) this.field = field;
	}
}

// Some specific parsing errors/exceptions

export class NonNegIntException extends ParseError {
	constructor(message: string) {
		super('NonNegIntException', message);
	}
}

export class UsernameParseException extends ParseError {
	constructor(message: string) {
		super('UsernameParseExcpeption', message, 'username');
	}
}

export class EmailParseException extends ParseError {
	constructor(message: string) {
		super('EmailParseException', message, 'email');
	}
}

export class NonNegDecimalException extends ParseError {
	constructor(message: string) {
		super('NonNegDecimalException', message);
	}
}

export class BooleanParseException extends ParseError {
	constructor(message: string) {
		super('BooleanParseException', message);
	}
}

export class NumberParseException extends ParseError {
	constructor(message: string) {
		super('NumberParseException', message);
	}
}

export class StringParseException extends ParseError {
	constructor(message: string) {
		super('StringParseException', message);
	}
}

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
	if (typeof val === 'string' && (mailRE.test(`${val}`) || usernameRE.test(`${val}`))) {
		return val;
	} else {
		throw new UsernameParseException(`The value '${val?.toString() ?? ''}'' is not a value username`);
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

export type UserRole = 'admin' | 'instructor' | 'TA' | 'student';

export function parseUserRole(role: string): UserRole {
	if (role === 'admin') return 'admin';
	if (role === 'instructor') return 'instructor';
	if (role === 'TA') return 'TA';
	if (role === 'student') return 'student';
	throw new UserRoleException(`The value '${role}' is not a valid role.`);
}

export function parseString(_value: string | number | boolean) {
	if (typeof _value !== 'string') {
		throw new StringParseException(`The value '${_value.toString()}' is not a string.`);
	} else {
		return _value;
	}
}

// General Parsing error

export class ParseError {
	type: string;
	message: string;
	field?: string;
	constructor(type: string, message: string) {
		this.type = type;
		this.message = message;
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
		super('UsernameParseExcpeption', message);
	}
}

export class EmailParseException extends ParseError {
	constructor(message: string) {
		super('EmailParseException', message);
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

// Parsing functions

export function parseNonNegInt(val: string | number) {
	if (/^\s*(\d+)\s*$/.test(`${val}`)) {
		return parseInt(`${val}`);
	} else {
		throw new NonNegIntException(`The value ${val} is not a non-negative integer`);
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

export const user_roles = ['admin', 'instructor', 'TA', 'student'];

export function parseUserRole(role: string) {
	if (user_roles.findIndex((v) => v === role) < 0) {
		const err = new ParseError('InvalidRole', `The value '${role}' is not a valid role`);
		err.field = 'role';
		throw err;
	}
	return role;
}

export function parseString(_value: string | number | boolean) {
	if (typeof _value !== 'string') {
		throw new StringParseException(`The value '${_value.toString()}' is not a string.`);
	} else {
		return _value;
	}
}

export interface Dictionary<T> {
	[key: string]: T;
}

// export class Model {
// constructor(params: Dictionary<string|number|boolean>) {
// // parse the individual fields
// }

// }

export interface ResponseError {
	exception: string;
	message: string;
}

export class ParseError {
	type: string;
	message: string;
	field?: string;
	constructor(type: string, message: string){
		this.type = type;
		this.message = message;
	}
}

export class NonNegIntException extends ParseError {
	constructor(message: string){
		super('NonNegIntException', message);
	}
}

export function parseNonNegInt(val: string | number) {
	if (/^\s*(\d+)\s*$/.test(`${val}`)) {
		return parseInt(`${val}`);
	} else {
		throw new NonNegIntException(`The value ${val} is not a non-negative integer`);
	}
}

export const mailRE = /^[\w.]+@([a-zA-Z_.]+)+\.[a-zA-Z]{2,9}$/;
export const usernameRE = /^[a-zA-Z]([a-zA-Z._0-9])+$/;

export class UsernameParseException extends ParseError {
	constructor(message: string){
		super('UsernameParseExcpeption', message);
	}
}

export function parseUsername(val: string | undefined) {
	if (typeof val === 'string' && (mailRE.test(`${val}`) || usernameRE.test(`${val}`))) {
		return val;
	} else {
		throw new UsernameParseException(`The value '${val?.toString() ?? ''}'' is not a value username`);
	}
}

export class EmailParseException extends ParseError {
	constructor(message: string){
		super('EmailParseException', message);
	}
}

export function parseEmail(val: string|undefined): string|undefined {
	if (typeof val === 'string' && mailRE.test(`${val}`)) {
		return val;
	} else {
		throw new EmailParseException(`The value '${val?.toString() ?? ''}' is not a value email`);
	}
}

export class BooleanParseException extends ParseError {
	constructor(message: string){
		super('BooleanParseException', message);
	}
}

const booleanRE = /^([01])|(true)|(false)$/;
const booleanTrue = /^(1)|(true)$/;

export function parseBoolean(_value: boolean | string | number) {
	if (typeof _value === 'boolean') return _value;
	if (typeof _value === 'number' && (_value === 1 || _value === 0)) {
		return _value === 1;
	}
	// if (typeof _value === 'string' && !(/[01]/.exec(_value))) {
	// return _value === 'true' || _value === 'false' ?
	// _value === 'true' :
	// undefined;
	// } else {
	// return _value === undefined ?
	// undefined :
	// parseInt(`${_value}`) === 1;
	// }
	if (typeof _value === 'string' && booleanRE.test(_value)){
		return booleanTrue.test(_value);
	}
	throw new BooleanParseException(`The value '${_value}' is not a boolean`);

}

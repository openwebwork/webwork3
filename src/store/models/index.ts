// general classes and parsing functions

import { intersection, isEqual, difference } from 'lodash';

export interface Dictionary<T> {
	[key: string]: T;
}

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
export const usernameRE = /^[_a-zA-Z]([a-zA-Z._0-9])+$/;

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
	if (typeof _value === 'string' && booleanRE.test(_value)){
		return booleanTrue.test(_value);
	}
	throw new BooleanParseException(`The value '${_value}' is not a boolean`);

}

export class RequiredFieldsException extends ParseError {
	constructor(_field: string, message: string,){
		super('RequiredFieldsException', message);
		super.field = _field;
	}
}

export class Model {
	_required_fields: Array<string> = [];
	_optional_fields?: Array<string> = [];

	get all_fields(): Array<string> {
		return [];
	}

	get required_fields() {
		return this._required_fields;
	}

	constructor(_params: Dictionary<number|string|boolean> = {}){
		// check that required fields are present
		const common_fields = intersection(this.required_fields, Object.keys(_params));

		if (!isEqual(common_fields, this.required_fields)) {
			const diff = difference(this.required_fields, common_fields);
			throw new RequiredFieldsException('_all',
				`The field(s) '${diff.join(', ')}' must be present in the model.`
			);
		}
	}
}

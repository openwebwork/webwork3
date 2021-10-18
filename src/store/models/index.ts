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

export const user_roles = ['admin', 'instructor', 'TA', 'student'];

export function parseUserRole(role: string) {
	if (user_roles.findIndex((v) => v === role) < 0) {
		const err = new ParseError('InvalidRole', `The value '${role}' is not a valid role`);
		err.field = 'role';
		throw err;
	}
	return role;
}

export class RequiredFieldsException extends ParseError {
	constructor(_field: string, message: string){
		super('RequiredFieldsException', message);
		super.field = _field;
	}
}

export class InvalidFieldsException extends ParseError {
	constructor(_field: string, message: string) {
		super('InvalidFieldsException', message);
		super.field = _field;
	}
}

interface ModelField  {
	[k: string]: {
		field_type: 'string'|'boolean'|'number'|'non_neg_int'|'username'|'dictionary'|'email'|'role';
		default_value?: generic|Dictionary<generic|undefined>;
	}
}

export type generic = string|number|boolean;

/* This creates a general Model to be used for all others (Course, User, etc.)

The original structure of this was from a SO answer at
https://stackoverflow.com/questions/69590729/creating-a-class-using-typescript-with-specific-fields */

export const Model = <R extends string, O extends string, F extends ModelField>
	(requiredFields: R[], optionalFields: O[], fields: F) => {

	type ModelObject<R extends string, O extends string> =
			Record<R, generic|Dictionary<generic>>
				& Partial<Record<O, generic|Dictionary<generic|undefined>>> extends
				infer T ? { [K in keyof T]: T[K] } : never;

	class _Model {
		_required_fields: Array<R> = requiredFields;
		_optional_fields?: Array<O> = optionalFields;
		_fields: F = fields;

		constructor(params?: ModelObject<R, O>) {
			// check that required fields are present

			const common_fields = intersection(this._required_fields, Object.keys(params ?? {}));

			if (!isEqual(common_fields, this._required_fields)) {
				const diff = difference(this._required_fields, common_fields);
				throw new RequiredFieldsException('_all',
					`The field(s) '${diff.join(', ')}' must be present in ${this.constructor.name}`);
			}

			// check that no invalid params are set
			const invalid_fields = difference(Object.keys(params ?? {}), this.all_fields);
			if (invalid_fields.length !== 0) {
				throw new InvalidFieldsException('_all',
					`The field(s) '${invalid_fields.join(', ')}' are not valid for ${this.constructor.name}.`);
			}
			this.set(params ?? {});
		}

		/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access,
			@typescript-eslint/no-explicit-any */

		set(params: Partial<ModelObject<R, O>>) {
			this.all_fields.forEach(key => {
				// if the field is undefined in the params, but there is a default value, set it
				if ((params as any)[key] === undefined && this._fields[key].default_value !== undefined) {
					(params as any)[key] = this._fields[key].default_value;
				}
				// parse each field
				if ((params as any)[key] !== undefined && this._fields[key].field_type === 'boolean') {
					(this as any)[key] = parseBoolean((params as any)[key]);
				} else if ((params as any)[key] !== undefined && this._fields[key].field_type === 'string') {
					(this as any)[key] = `${(params as any)[key] as string}`;
				} else if ((params as any)[key] !== undefined && this._fields[key].field_type === 'non_neg_int') {
					(this as any)[key] = parseNonNegInt((params as any)[key]);
				} else if ((params as any)[key] !== undefined && this._fields[key].field_type === 'username') {
					(this as any)[key] = parseUsername((params as any)[key]);
				} else if ((params as any)[key] !== undefined && this._fields[key].field_type === 'email') {
					(this as any)[key] = parseEmail((params as any)[key]);
				} else if ((params as any)[key] !== undefined && this._fields[key].field_type === 'role') {
					(this as any)[key] = parseUserRole((params as any)[key]);
				}
			});
		}

		get all_fields(): Array<R | O> {
			return [...this._required_fields, ...this._optional_fields ?? []];
		}

		get required_fields() {
			return this._required_fields;
		}

		// converts the instance of the class to an regular object.
		toObject() {
			const obj: Dictionary<generic> = {};
			this.all_fields.forEach(key => {
				if((this as any)[key] !== undefined){
					obj[key] = (this as any)[key];
				}
			});
			return obj;
		}
		/* eslint-enable */
	}

	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	return _Model as any as new (params?: ModelObject<R, O>) =>
		ModelObject<R, O> & {
			set(params: Partial<ModelObject<R, O>>): void,
			toObject(): Dictionary<generic>,
			all_fields: Array<R | O>;
			required_fields: R[];
		} extends infer T ? { [K in keyof T]: T[K] } : never;
};

// export class Model {
// _required_fields: Array<string> = [];
// _optional_fields?: Array<string> = [];

// get all_fields(): Array<string> {
// return [];
// }

// get required_fields() {
// return this._required_fields;
// }

// constructor(_params: Dictionary<number|string|boolean> = {}){
// // check that required fields are present
// const common_fields = intersection(this.required_fields, Object.keys(_params));

// if (!isEqual(common_fields, this.required_fields)) {
// const diff = difference(this.required_fields, common_fields);
// throw new RequiredFieldsException('_all',
// `The field(s) '${diff.join(', ')}' must be present in the model.`
// );
// }
// }
// }

/* This find contains three types of functionality
	1) some basic interfaces for non-specific models.
	2) some parsing functions for most types
	3) the general Model class for handling parsing of all basic object types (Course, ProblemSet, User)

*/

import { pick, pickBy } from 'src/common/utils';

export interface Dictionary<T> {
	[key: string]: T;
}

// General Error coming from the API service

export interface ResponseError {
	exception: string;
	message: string;
}

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

export class RequiredFieldsException extends ParseError {
	constructor(_field: string, message?: string) {
		const msg = message ?? `You must provide the field '${_field}'`;
		super('RequiredFieldsException', msg);
		this.field = _field;
	}
}

export class InvalidFieldsException extends ParseError {
	constructor(_field: string, message: string) {
		super('InvalidFieldsException', message);
		this.field = _field;
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

export const user_roles = ['admin', 'instructor', 'TA', 'student'];

export function parseUserRole(role: string) {
	if (user_roles.findIndex((v) => v === role) < 0) {
		const err = new ParseError('InvalidRole', `The value '${role}' is not a valid role`);
		err.field = 'role';
		throw err;
	}
	return role;
}

export type generic = string | number | boolean;

export type ParseableModel = Dictionary<generic | Dictionary<generic>>;

// This interface is a general field for a model.

export interface ModelField {
	[k: string]: {
		field_type: 'string' | 'boolean' | 'number' | 'non_neg_int' | 'username' | 'email' | 'role' | 'array';
		default_value?: generic | Dictionary<generic> | Array<Dictionary<generic>>;
		required?: boolean;
	};
}

export const parseParams = (_params: Dictionary<generic | Dictionary<generic>>, _fields: ModelField) => {
	const output_params: Dictionary<generic> = {};
	Object.keys(_fields).forEach((key: string) => {
		const paramValue = (!(key in _params) || _params[key] == undefined) && _fields[key].default_value !== undefined
			? _fields[key].default_value as generic | Dictionary<generic>
			: _params[key];
		// parse each field
		if (paramValue != undefined && _fields[key].field_type === 'boolean') {
			output_params[key as keyof Dictionary<generic>] = parseBoolean(paramValue as string | number | boolean);
		} else if (paramValue != undefined && _fields[key].field_type === 'string') {
			output_params[key as keyof Dictionary<generic>] = `${paramValue as string}`;
		} else if (paramValue != undefined && _fields[key].field_type === 'non_neg_int') {
			output_params[key as keyof Dictionary<generic>] = parseNonNegInt(paramValue as string | number);
		} else if (paramValue != undefined && _fields[key].field_type === 'username') {
			output_params[key as keyof Dictionary<generic>] = parseUsername(paramValue as string);
		} else if (paramValue != undefined && _fields[key].field_type === 'email') {
			output_params[key as keyof Dictionary<generic>] = parseEmail(paramValue as string);
		} else if (paramValue != undefined && _fields[key].field_type === 'role') {
			output_params[key as keyof Dictionary<generic>] = parseUserRole(paramValue as string);
		}
	});
	return output_params;
};

/* This creates a general Model to be used for all others (Course, User, etc.)

The original structure of this was from a SO answer at
https://stackoverflow.com/questions/69590729/creating-a-class-using-typescript-with-specific-fields

This is a factory that will build a new class.  It takes 5 arguments.  The first is each is an array of strings.
* array of boolean field names
* array of number field names
* array of string field names
* array of dictionary field names
* dictionary of field types (see ModelField above)

To create a new class, extend Model.

For example a User model will be

export class User extends Model(
	['is_admin'], ['user_id'], ['username', 'email', 'first_name', 'last_name', 'student_id'], [],
	{
		username: { field_type: 'username', required: true },
		email: { field_type: 'email' },
		user_id: { field_type: 'non_neg_int', default_value: 0 },
		first_name: { field_type: 'string' },
		last_name: { field_type: 'string' },
		is_admin: { field_type: 'boolean', default_value: false },
		student_id: { field_type: 'string' }
	})
)

*/

export const Model = <
	Bool extends string,
	Num extends string,
	Str extends string,
	Dic extends string,
	F extends ModelField
>(
		boolean_fields: Bool[],
		Num_neg_int_fields: Num[],
		string_fields: Str[],
		dictionary_fields: Dic[],
		fields: F
	) => {
	type ModelObject<Bool extends string, Num extends string, Str extends string, Dic extends string> = Partial<
		Record<Bool, boolean>
	> &
		Partial<Record<Num, number>> &
		Partial<Record<Str, string>> &
		Partial<Record<Dic, Dictionary<generic>>> extends infer T
		? { [K in keyof T]: T[K] }
		: never;

	class _Model {
		_boolean_field_names: Array<Bool> = boolean_fields;
		_number_field_names: Array<Num> = Num_neg_int_fields;
		_string_field_names: Array<Str> = string_fields;
		_dictionary_field_names: Array<Dic> = dictionary_fields;
		_fields: F = fields;

		constructor(params: Dictionary<generic | Dictionary<generic>> = {}) {
			// Check that required fields are present.
			const missing_fields = this.required_fields.filter(field => !Object.keys(params).includes(field));
			if (missing_fields.length) {
				throw new RequiredFieldsException(
					'_all',
					`The field(s) '${missing_fields.join(', ')}' must be present in ${this.constructor.name}`
				);
			}

			// Check that no invalid params are set.
			const invalid_fields = Object.keys(params).filter(
				param => !this.all_fields.includes(param as Bool | Num | Str | Dic)
			);
			if (invalid_fields.length) {
				throw new InvalidFieldsException(
					'_all',
					`The field(s) '${invalid_fields.join(', ')}' is(are) not valid for ${this.constructor.name}.`
				);
			}
			this.set(params);
		}

		set(params: Dictionary<generic | Dictionary<generic> | Array<Dictionary<generic>>>) {
			// parse the non-object fields;
			const fields = [...this._boolean_field_names, ...this._number_field_names, ...this._string_field_names];
			const parsed_params = parseParams(pick(params, fields) as Dictionary<generic>, this._fields);

			fields.forEach((key) => {
				if (key in parsed_params && parsed_params[key] != null) {
					(this as unknown as Dictionary<generic>)[key] = parsed_params[key];
				}
			});
		}

		get all_fields(): Array<Bool | Num | Str | Dic> {
			return [
				...this._boolean_field_names,
				...this._number_field_names,
				...this._string_field_names,
				...this._dictionary_field_names,
			];
		}

		get required_fields() {
			return Object.keys(pickBy(this._fields, (val: { required?: boolean }) => val.required || false));
		}

		// converts the instance of the class to an regular object.
		toObject(_fields?: Array<string>) {
			const obj: Dictionary<generic> = {};
			const fields = _fields ?? this.all_fields;
			fields.forEach((key) => {
				if ((this as unknown as Dictionary<generic>)[key] !== undefined) {
					obj[key] = (this as unknown as Dictionary<generic>)[key];
				}
			});
			return obj;
		}

		/* eslint-enable */
	}

	return _Model as unknown as new (
		params?: Dictionary<generic | Dictionary<generic> | Array<Dictionary<generic>>>
	) => ModelObject<Bool, Num, Str, Dic> & {
		set(params: Dictionary<generic | Dictionary<generic>>): void;
		toObject(_fields?: Array<string>): Dictionary<generic>;
		all_fields: Array<Bool | Num | Str | Dic>;
		required_fields: Array<Bool | Num | Str | Dic>[];
	} extends infer T
		? { [K in keyof T]: T[K] }
		: never;
};

export class Collection {
	_class_name: string;
	constructor(class_name: string) {
		this._class_name = class_name;
	}
}

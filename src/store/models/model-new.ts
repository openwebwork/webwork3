// This is the Model Params as a Class

import { parseNonNegInt, parseBoolean, parseUsername, parseUserRole, parseEmail,
	parseNumber, parseString } from './parsers-new';

import { pickBy } from 'src/common/utils';

export interface Dictionary<T> {
	[key: string]: T;
}
export type generic = string | number | boolean;

export type ModelFieldType = 'string' | 'boolean' | 'number' | 'non_neg_int' | 'username' | 'email' |
'role' | 'params';

export class ParseError {
	type: string;
	message: string;
	field?: string;
	constructor(type: string, message: string) {
		this.type = type;
		this.message = message;
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

export interface WithFields {
	boolean_field_names: string[];
	number_field_names: string[];
	string_field_names: string[];
	required_field_names: string[];
	all_field_names: string[];
	field_types: ModelField;
}

export interface ModelField {
	[k: string]: {
		field_type: ModelFieldType;
		default_value?: generic;
		required?: boolean;
		param_class?: string;
	};
}

const fillMissingFields = (model: WithFields, field_names: Array<string>) => {
	const missing_fields = field_names.filter(field => Object.keys(model.field_types).indexOf(field) < 0);
	missing_fields.forEach(field => {
		if (model.boolean_field_names.findIndex(name => name === field) >= 0) {
			(model.field_types as unknown as Dictionary<{ field_type: string }>)[field] = { field_type: 'boolean' };
		} else if (model.number_field_names.findIndex(name => name === field) >= 0) {
			(model.field_types as unknown as Dictionary<{ field_type: string }>)[field] = { field_type: 'number' };
		} else if (model.string_field_names.findIndex(name => name === field) >= 0) {
			(model.field_types as unknown as Dictionary<{ field_type: string }>)[field] = { field_type: 'string' };
		}
	});
};

const checkRequiredfields = (model: WithFields, param_field_names: string[]) => {
	const common_fields = model.required_field_names.filter(field => param_field_names.indexOf(field) >= 0);
	if (common_fields.length !== model.required_field_names.length) {
		const diff = model.required_field_names.filter(field => common_fields.indexOf(field) < 0);
		const fields = diff.join(', ');
		const error = `The field(s) '${fields}' must be present in ${model.constructor.name}`;
		throw new RequiredFieldsException(fields, error);
	}
};

const checkForInvalidFields = (model: WithFields, field_names: string []) => {
	const invalid_fields = field_names.filter(field => model.all_field_names.indexOf(field) < 0);
	if (invalid_fields.length !== 0) {
		const fields = invalid_fields.join(', ');
		const error = `The field(s) '${fields}' is(are) not valid for ${model.constructor.name}.`;
		throw new InvalidFieldsException(fields, error);
	}
};

export const parseParams = (_params: Partial<Dictionary<generic | Dictionary<generic>>>, _fields: ModelField) => {
	const output_params: Dictionary<generic> = {};
	Object.keys(_fields).forEach((key: string) => {
		// set the default value if missing and default_value exists
		if ((!(key in _params) || _params[key] == undefined) && _fields[key].default_value != undefined) {
			// Not sure why typescript isn't allowing without type conversion
			output_params[key] = _fields[key].default_value as unknown as generic;
		}
		// parse each field
		if (key in _params && _params[key] != undefined && _fields[key].field_type === 'boolean') {
			output_params[key as keyof Dictionary<generic>] = parseBoolean(_params[key] as string | number | boolean);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'string') {
			output_params[key as keyof Dictionary<generic>] = parseString(_params[key] as string | number | boolean);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'non_neg_int') {
			output_params[key as keyof Dictionary<generic>] = parseNonNegInt(_params[key] as string | number);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'username') {
			output_params[key as keyof Dictionary<generic>] = parseUsername(_params[key] as string);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'email') {
			output_params[key as keyof Dictionary<generic>] = parseEmail(_params[key] as string);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'role') {
			output_params[key as keyof Dictionary<generic>] = parseUserRole(_params[key] as string);
		} else if (key in _params && _params[key] != undefined && _fields[key].field_type === 'number') {
			output_params[key as keyof Dictionary<generic>] = parseNumber(_params[key] as string);
		}
	});
	return output_params;
};

export const ModelParams = <
	Bool extends string,
	Num extends string,
	Str extends string,
	F extends ModelField
>(
		boolean_fields: Bool[],
		number_fields: Num[],
		string_fields: Str[],
		field_types: F
	) => {
	type ModelParamsObject<Bool extends string, Num extends string, Str extends string>
	= Partial<Record<Bool, boolean>> &
		Partial<Record<Num, number>> &
		Partial<Record<Str, string>> extends infer T
		? { [K in keyof T]: T[K] }
		: never;

	class _Model_Params {
		_boolean_field_names: Array<Bool> = boolean_fields;
		_number_field_names: Array<Num> = number_fields;
		_string_field_names: Array<Str> = string_fields;
		_field_types: F = field_types;

		constructor(params: Dictionary<generic> = {}) {
			// If there are any fields defined in the model that aren't present in the
			// fields object, fill them with defaults:
			fillMissingFields(this, this.all_field_names);

			// check that required fields are present
			checkRequiredfields(this, Object.keys(params));

			// check that no invalid params are set
			// checkForInvalidFields(this, Object.keys(params));

			const parsed_params = parseParams(params, this._field_types);
			this.all_field_names.forEach((key) => {
				if (key in parsed_params && parsed_params[key] != null) {
					(this as unknown as Dictionary<generic>)[key] = parsed_params[key];
				}
			});
		}

		get required_field_names() {
			return Object.keys(pickBy(this._field_types, (val: { required?: boolean }) => val.required || false));
		}

		get all_field_names(): Array<Bool | Num | Str > {
			return [
				...this._boolean_field_names,
				...this._number_field_names,
				...this._string_field_names,
			];
		}

		get field_types(): ModelField {
			return this._field_types;
		}

		set(params: Partial<Dictionary<generic>>) {
			// Check that no invalid params are set.
			// checkForInvalidFields(this, Object.keys(params));

			// Parse and assign only params that are passed in.
			const parsed_params = parseParams(params, this._field_types);
			Object.keys(params).forEach((key) => {
				(this as unknown as Dictionary<generic>)[key] = parsed_params[key];
			});
		}

		get boolean_field_names(): Array<Bool> {
			return this._boolean_field_names;
		}

		get number_field_names(): Array<Num> {
			return this._number_field_names;
		}

		get string_field_names(): Array<Str> {
			return this._string_field_names;
		}

		// converts the instance of the class to an regular object.
		toObject(_fields?: Array<string>) {
			const obj: Dictionary<generic> = {};
			const fields = _fields ?? this.all_field_names;
			fields.forEach((key) => {
				if (this[key as keyof this] !== undefined) {
					obj[key] = (this as unknown as Dictionary<generic>)[key];
				}
			});
			return obj;
		}
	}

	return _Model_Params as unknown as
		new (params?: Dictionary<generic>) => ModelParamsObject<Bool, Num, Str> &
		WithFields & ParamMethods;
};

interface ParamMethods {
	toObject(_fields?: Array<string>): Dictionary<generic>;
	set(params: Partial<Dictionary<generic>>): void;
}

export class Model {

	get all_field_names(): string[] {
		throw 'You must override this method.';
	}

	get param_fields(): string[] {
		throw 'You must override this method in a subclass.';
	}

	toObject(_fields?: string[]): Dictionary<generic | Dictionary<generic>> {
		const obj: Dictionary<generic | Dictionary<generic>> = {};
		const fields = _fields ?? this.all_field_names;
		fields.forEach((key) => {
			if (this[key as keyof this] !== undefined) {
				if (this.param_fields.indexOf(key) >= 0) {
					const param_obj = (this as unknown as Dictionary<generic>)[key] as
						unknown as { toObject(): Dictionary<generic>};
					obj[key] = param_obj.toObject();
				} else {
					obj[key] = (this as unknown as Dictionary<generic>)[key];
				}
			}
		});
		return obj;
	}

	clone(): Model {
		throw 'The clone method must be overridden in a subclass.';
	}

}

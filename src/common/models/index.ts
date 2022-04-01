// This is the Model as a Class

import { ParseError } from './parsers';
export interface Dictionary<T> {
	[key: string]: T;
}
export type generic = string | number | boolean;

export class RequiredFieldsException extends ParseError {
	constructor(_field: string, message?: string) {
		const msg = message ?? `You must provide the field '${_field}'`;
		super('RequiredFieldsException', msg);
		this.field = _field;
	}
}

export class InvalidFieldsException extends ParseError {
	constructor(_field: string, message?: string) {
		const msg = message ?? `The field ${_field} is not valid.`;
		super('InvalidFieldsException', msg);
		this.field = _field;
	}
}
export class Model {

	get all_field_names(): string[] {
		throw 'You must override the getter all_field_names in the subclass.';
	}

	get param_fields(): string[] {
		throw 'You must override the getter param_fields in the subclass.';
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

	checkParams(params: Dictionary<generic | Dictionary<generic>>) {
		const invalid_fields = Object.keys(params).filter(field => this.all_field_names.indexOf(field) < 0);
		if (invalid_fields.length !== 0) {
			const fields = invalid_fields.join(', ');
			const error = `The field(s) '${fields}' is(are) not valid for ${this.constructor.name}.`;
			throw new InvalidFieldsException(fields, error);
		}
	}

}

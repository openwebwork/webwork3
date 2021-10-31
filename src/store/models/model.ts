
import { Dictionary, generic, ModelField, parseBoolean, parseEmail, parseUserRole,
	parseNonNegInt, parseUsername, RequiredFieldsException, InvalidFieldsException } from './index';
import { assign, intersection, isEqual, difference } from 'lodash';

/* the follow is the previous version of Model and some space to try other things.

*/

export const Model = <Req extends string, Opt extends string, Dic extends string, F extends ModelField>
	(requiredFields: Req[], optionalFields: Opt[], dictionaryFields: Dic[], fields: F) => {

	type ModelObject<Req extends string, Opt extends string, Dic extends string> =
			Record<Req, generic> & Partial<Record<Opt, generic>> &
			Partial<Record<Dic, Partial<Dictionary<generic>>>> extends
				 infer T ? { [K in keyof T]: T[K] } : never;

	class _Model {
		_required_fields: Array<Req> = requiredFields;
		_optional_fields?: Array<Opt> = optionalFields;
		_dictionary_fields?: Array<Dic> = dictionaryFields;
		_fields: F = fields;

		constructor(params?: ModelObject<Req, Opt, Dic>) {
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

		set(params: Partial<ModelObject<Req, Opt, Dic>>) {
			const fields = [...this._optional_fields ?? [], ...this._required_fields];
			fields.forEach(key => {
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
			assign(this, params, this._dictionary_fields);
		}

		get all_fields(): Array<Req | Opt | Dic> {
			return [...this._required_fields, ...this._optional_fields ?? [], ...this._dictionary_fields ?? []];
		}

		get required_fields() {
			return this._required_fields;
		}

		// converts the instance of the class to an regular object.
		toObject(_fields?: Array<string>) {
			const obj: Dictionary<generic> = {};
			const fields = _fields ?? this.all_fields;
			fields.forEach(key => {
				if((this as any)[key] !== undefined){
					obj[key] = (this as any)[key];
				}
			});
			return obj;
		}
		/* eslint-enable */
	}

	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	return _Model as any as new (params?: ModelObject<Req, Opt, Dic>) =>
		ModelObject<Req, Opt, Dic> & {
			set(params: Partial<ModelObject<Req, Opt, Dic>>): void,
			toObject(_fields?: Array<string>): Dictionary<generic>,
			all_fields: Array<Req | Opt | Dic>;
			required_fields: Req[];
		} extends infer T ? { [K in keyof T]: T[K] } : never;
};

interface ModelParams {
	field_name: string;
	field_type: 'string'|'boolean'|'number'|'non_neg_int'|'username'|'email'|'role'|'array';
	default_value?: generic|Dictionary<generic>|Array<Dictionary<generic>>;
	required?: boolean;
}

const NewModel = <NF extends string, BF extends string, F extends Array<ModelParams>>
	(fields: F) => {

		type ModelObject <NF extends string, BF extends string> =
				Partial<Record<NF, generic>> & Partial<Record<BF, generic>> extends
					infer T ? { [K in keyof T]: T[K] } : never;

		class _Model {
		_number_fields: Array<NF> = [];
		_boolean_fields: Array<BF> = [];
		_field_params = fields;

		constructor(params: Dictionary<generic | Dictionary<generic>>= {}) {
			console.log(params);
			this._field_params.forEach(p => {
				if (p.field_type === 'boolean') {
					this._boolean_fields.push(p.field_name as BF);
				} else if (p.field_type === 'non_neg_int') {
					this._number_fields.push(p.field_name as NF);
				}
			});
		}
		}

		return _Model as unknown as new (params?: Dictionary<generic | Dictionary<generic>>) =>
	ModelObject<NF, BF> & {
		set(params: Dictionary<generic | Dictionary<generic>>): void,
		// toObject(_fields?: Array<string>): Dictionary<generic>,
		// all_fields: Array<NF | BF>;
		// required_fields: Array<NF | BF>;
	} extends infer T ? { [K in keyof T]: T[K] } : never;
};

export class User extends NewModel([
	{ field_name: 'username', field_type: 'username', required: true },
	{ field_name: 'email', field_type: 'email' },
	{ field_name: 'user_id', field_type: 'non_neg_int', default_value: 0 },
	{ field_name: 'first_name', field_type: 'string' },
	{ field_name: 'last_name', field_type: 'string' },
	{ field_name: 'is_admin', field_type: 'boolean', default_value: false },
	{ field_name: 'student_id', field_type: 'string' }
]) {

}

const user = new User();
user.username = 'fred';
user.flfe;

console.log(user);

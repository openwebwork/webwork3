
import { Dictionary, generic, ModelField, parseBoolean, parseEmail, parseUserRole,
	parseNonNegInt, parseUsername, RequiredFieldsException, InvalidFieldsException } from './index';
import { assign, intersection, isEqual, difference } from 'lodash';

/* the follow is the previous version of Model */

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

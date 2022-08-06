
/* These are related to Course Settings */

import { Model } from '.';
import { isTime, isTimeDuration } from './parsers';

export enum SettingType {
	int = 'int',
	decimal = 'decimal',
	list = 'list',
	multilist = 'multilist',
	text = 'text',
	boolean = 'boolean',
	time_duration = 'time_duration',
	timezone = 'timezone',
	time = 'time',
	unknown = 'unknown'
}

export interface OptionType {
	label: string;
	value: string;
};

export type SettingValueType = number | boolean | string | string[] | OptionType[];

export interface ParseableGlobalSetting {
	setting_id?: number;
	setting_name?: string;
	category?: string;
	subcategory?: string;
	description?: string;
	doc?: string;
	type?: string;
	options?: string[] | OptionType[];
	default_value?: SettingValueType;
}

export class GlobalSetting extends Model {
	private _setting_id = 0;
	private _setting_name = '';
	private _default_value: SettingValueType = '';
	private _category = '';
	private _subcategory?: string;
	private _options?: string[] | OptionType[];
	private _description = '';
	private _doc?: string;
	private _type: SettingType = SettingType.unknown;

	constructor(params: ParseableGlobalSetting = {}) {
		super();
		this.set(params);
	}

	static ALL_FIELDS = ['setting_id', 'setting_name', 'default_value', 'category',
		'subcategory', 'description', 'doc', 'type', 'options'];
	get all_field_names(): string[] { return GlobalSetting.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	set(params: ParseableGlobalSetting) {
		if (params.setting_id != undefined) this.setting_id = params.setting_id;
		if (params.setting_name != undefined) this.setting_name = params.setting_name;
		if (params.default_value != undefined) this.default_value = params.default_value;
		if (params.category != undefined) this.category = params.category;
		this.subcategory = params.subcategory;
		if (params.description != undefined) this.description = params.description;
		this.doc = params.doc;
		if (params.type != undefined) this.type = params.type;
		this.options = params.options;
	}

	get setting_id() { return this._setting_id; }
	set setting_id(v: number) { this._setting_id = v; }

	get setting_name() { return this._setting_name; }
	set setting_name(v: string) { this._setting_name = v; }

	get default_value() { return this._default_value; }
	set default_value(v: SettingValueType) { this._default_value = v; }

	get category() { return this._category; }
	set category(v: string) { this._category = v; }

	get subcategory() { return this._subcategory; }
	set subcategory(v: string | undefined) { this._subcategory = v; }

	get options() { return this._options; }
	set options(v: undefined | string[] | OptionType[]) { this._options = v; }

	get description() { return this._description; }
	set description(v: string) { this._description = v; }

	get doc() { return this._doc; }
	set doc(v: string | undefined) { this._doc = v; }

	get type() { return this._type; }
	set type(v: string) { this._type = parseSettingType(v); }

	clone(): GlobalSetting { return new GlobalSetting(this.toObject()); }

	/**
	 * returns whether or not the setting is valid.  The name, category and description fields cannot
	 * be the empty string, and the type cannot be unknown.
	 */

	isValid() { return this.setting_name.length > 0 && this.category.length > 0 && this.description.length > 0
		&& validSettingValue(this, this.default_value); }
}

/**
	 * This checks if the value is consistent with the type of the setting.
	 */
const validSettingValue = (setting: GlobalSetting | CourseSetting, v: SettingValueType): boolean  => {
	const opts = setting.options;
	switch (setting.type) {
	case SettingType.int: return typeof(v) === 'number' && Number.isInteger(v);
	case SettingType.decimal: return typeof(v) === 'number';
	case SettingType.list:
		return opts != undefined && Array.isArray(opts) && opts[0] != undefined
		&& (Object.prototype.hasOwnProperty.call(opts[0], 'label') ?
			// opts is OptionType
			(opts as OptionType[]).map(o => o.value).includes(v as string) :
			// opts is a string
			(opts as string[]).includes(v as string));
	case SettingType.multilist:
		return opts != undefined && Array.isArray(opts) && opts[0] != undefined
		&& (Object.prototype.hasOwnProperty.call(opts[0], 'label') ?
			// opts is OptionType[]
			(v as string[]).every(x => (opts as OptionType[]).map(o => o.value).includes(x)) :
			// opts is string[]
			(v as string[]).every(x => (opts as string[]).includes(x)));
	case SettingType.text: return typeof(v) === 'string';
	case SettingType.boolean: return typeof(v) === 'boolean';
	case SettingType.time: return typeof(v) === 'string' && isTime(v);
	case SettingType.time_duration: return typeof(v) === 'string' && isTimeDuration(v);
	case SettingType.timezone: return typeof(v) === 'string';
	default: return false;

	}
};

const parseSettingType = (v: string): SettingType => {
	switch (v.toLowerCase()) {
	case 'int': return SettingType.int;
	case 'decimal': return SettingType.decimal;
	case 'list': return SettingType.list;
	case 'multilist': return SettingType.multilist;
	case 'text': return SettingType.text;
	case 'boolean': return SettingType.boolean;
	case 'time': return SettingType.time;
	case 'time_duration': return SettingType.time_duration;
	case 'timezone': return SettingType.timezone;
	default:
		return SettingType.unknown;
	}
};

/**
 * This is a parseable version for the course settting in the database.
 */

export interface ParseableDBCourseSetting {
	course_setting_id?: number;
	course_id?: number;
	setting_id?: number;
	value?: SettingValueType;
}

/**
 * A DBCourseSetting is a CourseSetting in the database with foreign keys for
 * the course and the global setting.
 */
export class DBCourseSetting extends Model {
	private _course_setting_id = 0;
	private _course_id = 0;
	private _setting_id = 0;
	private _value?: SettingValueType;

	constructor(params: ParseableDBCourseSetting = {}) {
		super();
		this.set(params);
	}

	static ALL_FIELDS = ['course_setting_id', 'course_id', 'setting_id', 'value'];
	get all_field_names(): string[] { return DBCourseSetting.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	set(params: ParseableDBCourseSetting) {
		if (params.course_setting_id != undefined) this.course_setting_id = params.course_setting_id;
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.setting_id != undefined) this.setting_id = params.setting_id;
		this.value = params.value;
	}

	get course_setting_id() { return this._course_setting_id; }
	set course_setting_id(v: number) { this._course_setting_id = v; }

	get setting_id() { return this._setting_id; }
	set setting_id(v: number) { this._setting_id = v; }

	get course_id() { return this._course_id; }
	set course_id(v: number) { this._course_id = v; }

	get value() { return this._value; }
	set value(v: SettingValueType | undefined) { this._value = v; }

	isValid(): boolean {
		return true;
	}

	clone(): DBCourseSetting {
		return new DBCourseSetting(this.toObject());
	}
}

export interface ParseableCourseSetting {
	setting_id?: number;
	course_setting_id?: number;
	course_id?: number;
	value?: SettingValueType;
	setting_name?: string;
	category?: string;
	subcategory?: string;
	description?: string;
	doc?: string;
	type?: string;
	options?: string[] | OptionType[];
	default_value?: SettingValueType;
}

/**
 * A CourseSetting is a merge between a GlobalSetting and any override from the
 * DBCourseSetting.
 */

export class CourseSetting extends Model {
	private _setting_id = 0;
	private _course_setting_id = 0;
	private _course_id = 0;
	private _setting_name = '';
	private _default_value: SettingValueType = '';
	private _value?: SettingValueType;
	private _category = '';
	private _subcategory?: string;
	private _options?: string[] | OptionType[];
	private _description = '';
	private _doc?: string;
	private _type: SettingType = SettingType.unknown;

	constructor(params: ParseableCourseSetting = {}) {
		super();
		this.set(params);
	}

	static ALL_FIELDS = ['setting_id', 'course_setting_id', 'course_id', 'value', 'setting_name',
		'default_value', 'category', 'subcategory', 'description', 'doc', 'type', 'options'];
	get all_field_names(): string[] { return CourseSetting.ALL_FIELDS; }
	get param_fields(): string[] { return []; }

	set(params: ParseableCourseSetting) {
		if (params.setting_id != undefined) this.setting_id = params.setting_id;
		if (params.course_setting_id != undefined) this.course_setting_id = params.course_setting_id;
		if (params.course_id != undefined) this.course_id = params.course_id;
		this.value = params.value;
		if (params.setting_name != undefined) this.setting_name = params.setting_name;
		if (params.default_value != undefined) this.default_value = params.default_value;
		if (params.category != undefined) this.category = params.category;
		this.subcategory = params.subcategory;
		if (params.description != undefined) this.description = params.description;
		this.doc = params.doc;
		if (params.type != undefined) this.type = params.type;
		this.options = params.options;
	}

	get setting_id() { return this._setting_id; }
	set setting_id(v: number) { this._setting_id = v; }

	get course_setting_id() { return this._course_setting_id; }
	set course_setting_id(v: number) { this._course_setting_id = v; }

	get course_id() { return this._course_id; }
	set course_id(v: number) { this._course_id = v; }

	get value(): SettingValueType { return this._value != undefined ? this._value : this.default_value; }
	set value(v: SettingValueType | undefined) { this._value = v; }

	get setting_name() { return this._setting_name; }
	set setting_name(v: string) { this._setting_name = v; }

	get default_value() { return this._default_value; }
	set default_value(v: SettingValueType) { this._default_value = v; }

	get category() { return this._category; }
	set category(v: string) { this._category = v; }

	get subcategory() { return this._subcategory; }
	set subcategory(v: string | undefined) { this._subcategory = v; }

	get options() { return this._options; }
	set options(v: undefined | string[] | OptionType[]) { this._options = v; }

	get description() { return this._description; }
	set description(v: string) { this._description = v; }

	get doc() { return this._doc; }
	set doc(v: string | undefined) { this._doc = v; }

	get type() { return this._type; }
	set type(v: string) { this._type = parseSettingType(v); }

	clone(): CourseSetting { return new CourseSetting(this.toObject()); }

	/**
	 * returns whether or not the setting is valid.  The name, category and description fields cannot
	 * be the empty string and the type cannot be unknown.
	 */

	isValid() { return this.setting_name.length > 0 && this.category.length > 0 && this.description.length > 0
		&& validSettingValue(this, this.default_value) && validSettingValue(this, this.value); }
}

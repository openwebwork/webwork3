
/* These are related to Course Settings */

export enum CourseSettingOption {
	int = 'int',
	decimal = 'decimal',
	list = 'list',
	multilist = 'multilist',
	text = 'text',
	boolean = 'boolean'
}

export class CourseSetting {
	var: string;
	value: string | number | boolean | Array<string>;
	constructor(params: { var?: string; value?: string|number|boolean|Array<string>}){
		this.var = params.var ?? '';
		this.value = params.value ?? '';
	}
}

export interface OptionType {
	label: string;
	value: string | number;
}

export interface CourseSettingInfo {
	var: string;
	category: string;
	doc: string;
	doc2: string;
	type: CourseSettingOption;
	options: Array<string> | Array<OptionType> | undefined;
	default: string | number | boolean;
}

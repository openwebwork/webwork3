export enum CourseSettingOption {
	int = 'int',
	decimal = 'decimal',
	list = 'list',
	multilist = 'multilist',
	text = 'text',
	boolean = 'boolean'
}

export interface OptionType {
	label: string;
	value: string | number;
}

export interface CourseSetting {
	var: string;
	value: string | number | boolean;
}

// This contains the default and documentation for a given course setting

export interface CourseSettingInfo {
	var: string;
	category: string;
	doc: string;
	doc2: string;
	type: CourseSettingOption;
	options: Array<string> | Array<CourseSetting> | undefined;
	default: string | number | boolean;
}
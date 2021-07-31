// This contains all of the interfaces for models throughout the app.

export interface Dictionary<T> {
  [key: string]: T;
}

export interface User {
	email: string;
	first_name: string;
	is_admin: number;
	last_name: string;
	login: string;
	student_id: string;
	user_id: number;
}

export interface UserCourse {
	course_id: number;
	course_user_id: number;
	user_id: number;
	course_name: string;
	params: Dictionary<string>;
	recitation: string;
	section: string;
	role: string;
}

export interface CourseUser {
	email: string;
	first_name: string;
	is_admin: number;
	last_name: string;
	login: string;
	student_id: string;
	user_id: number;
	role: string;
}

export interface SessionInfo {
  user: User;
  logged_in: boolean;
	message: string;
}

export interface UserPassword {
  email: string;
  password: string;
}

export interface Course {
	course_id: number;
	course_name: string;
}

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
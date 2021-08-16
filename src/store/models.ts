// This contains all of the interfaces for models throughout the app.

export interface Dictionary<T> {
	[key: string]: T;
}

export interface User {
	email: string;
	first_name: string;
	is_admin: boolean | number; // it comes in as a 0/1 boolean
	last_name: string;
	username: string;
	student_id: string;
	user_id: number | undefined;
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
	course_user_id: number;
	course_id: number;
	role: string;
	section: string;
	recitation: string;
	params: Dictionary<string>;
}

export interface SessionInfo {
	user: User;
	logged_in: boolean;
	message: string;
}

export interface UserPassword {
	username: string;
	password: string;
}

export interface CourseDates {
	start: string;
	end: string;
}

export interface Course {
	course_id: number;
	course_name: string;
	visible: boolean;
	course_dates: CourseDates;
}

export enum CourseSettingOption {
	int = 'int',
	decimal = 'decimal',
	list = 'list',
	multilist = 'multilist',
	text = 'text',
	boolean = 'boolean'
}

export interface CourseSetting {
	var: string;
	value: string | number | boolean;
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

export enum ProblemSetType {
	HW,
	QUIZ,
	REVIEW_SET
}

export interface ProblemSet {
	set_id: number;
	set_name: string;
	course_id: number;
	set_type: ProblemSetType;
	set_visible: boolean;
	params: Dictionary<string>;
	dates: Dictionary<string>;
}

export interface ResponseError {
	exception: string;
	message: string;
}

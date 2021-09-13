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
	course_user_id: number;
	user_id: number;
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

/* These are related to Course Settings */

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

/* These are Problem Set interfaces */

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW'
}

export interface ProblemSet {
	set_id: number;
	set_name: string;
	course_id: number;
	set_type: ProblemSetType;
	set_visible: boolean;
	params: ParamsType;
	dates: DatesType;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DatesType {
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface ParamsType {
}

export interface HomeworkSetParams extends ParamsType {
	enable_reduced_scoring?: boolean;
	hide_hint?: boolean;
	hardcopy_header?: string;
	set_header?: string;
	description?: string;
}

export interface HomeworkSetDates {
	open: number;
	reduced_scoring?: number;
	due: number;
	answer:number;
}

export interface HomeworkSet extends ProblemSet {
	params: HomeworkSetParams;
	dates: HomeworkSetDates;
}

export interface QuizDates extends DatesType {
	open: number;
	due: number;
	answer:number;
}

export interface QuizParams extends ParamsType {
	timed?: boolean;
	quiz_duration?: number;
}

export interface Quiz extends ProblemSet {
	params: QuizParams;
	dates: QuizDates;
}

export interface ReviewSetDates extends DatesType {
	open: number;
	closed: number;
}

export interface ReviewSetParams extends ParamsType {
	allow?: boolean;
}

export interface ReviewSet extends ProblemSet {
	params: ReviewSetParams;
	dates: ReviewSetDates;
}

export interface ParseableProblemSet {
	set_id: string | number;
	set_name: string;
	course_id: string | number;
	set_type: string;
	set_visible: string | number;
	params: Dictionary<string>;
	dates: Dictionary<string>;
}

export interface ResponseError {
	exception: string;
	message: string;
}

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

export enum CourseSettingType {
	int,
	decimal,
	list,
	multilist,
	text
}

// This contains the default and documentation for a given course setting

export interface CourseSettingInfo {
	var: string;
	category: string;
	doc: string;
	doc2: string;
	type: CourseSettingType;
	options?: Array<string>;
	default: string | number | boolean;
}

export interface CourseSetting {
	var: string;
	value: string | number | boolean;
}
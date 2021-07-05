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

export interface LoginInfo {
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

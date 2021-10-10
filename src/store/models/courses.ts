import { Dictionary } from 'src/store/models/index';

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

export interface CourseDates {
	start: string;
	end: string;
}

export interface ParseableCourse {
	course_id?: number;
	course_name?: string;
	visible?: boolean;
	course_dates?: CourseDates;
}

export class Course {
	course_id: number;
	course_name: string;
	visible: boolean;
	course_dates: CourseDates;

	constructor(params: ParseableCourse) {
		this.course_id = params.course_id ?? 0;
		this.course_name = params.course_name ?? '';
		this.visible = params.visible ?? true;
		this.course_dates = params.course_dates ?? { start: '', end: '' };
	}
}

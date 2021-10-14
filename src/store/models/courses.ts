import { Dictionary, parseNonNegInt, Model, parseBoolean } from '@/store/models/index';

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
	visible?: boolean | string | number;
	course_dates?: CourseDates;
}

export class Course extends Model {
	course_id: number;
	course_name?: string;
	visible?: boolean;
	course_dates: CourseDates;

	static REQUIRED_FIELDS = [];
	static OPTIONAL_FIELDS = ['course_id', 'course_name', 'visible', 'course_dates'];

	get required_fields() {
		return (this._required_fields?.length==0) ? Course.REQUIRED_FIELDS : [];
	}

	get all_fields() {
		return [...Course.REQUIRED_FIELDS, ...Course.OPTIONAL_FIELDS];
	}

	static get ALL_FIELDS() {
		return [...Course.REQUIRED_FIELDS, ...Course.OPTIONAL_FIELDS];
	}

	constructor(params: ParseableCourse = {}) {
		super(params as Dictionary<string|number|boolean>);
		this.course_dates = { start: '', end: '' };
		this.course_id = 0;
		this.set(params);
	}

	set(params: ParseableCourse) {
		if (params.course_id != null) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (params.course_name != null) {
			this.course_name = params.course_name;
		}
		if (params.visible != null) {
			this.visible = parseBoolean(params.visible);
		}
		if (params.course_dates?.start) {
			this.course_dates.start = params.course_dates?.start;
		}
		if (params.course_dates?.end) {
			this.course_dates.end = params.course_dates?.end;
		}
	}

}

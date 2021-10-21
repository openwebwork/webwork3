import { Dictionary, Model, generic } from '@/store/models/index';

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

export interface CourseDates extends Dictionary<generic> {
	start: string;
	end: string;
}

export interface ParseableCourse {
	course_id?: number;
	course_name?: string;
	visible?: boolean | string | number;
	course_dates?: CourseDates;
}

export class Course extends Model([], ['course_id', 'course_name', 'visible'],
	['course_dates'],
	{
		course_id: { field_type: 'non_neg_int', default_value: 0 },
		course_name: { field_type: 'string' },
		visible: { field_type: 'boolean', default_value: false }
	}) {

	course_dates: CourseDates = { start: '', end: '' };

	static REQUIRED_FIELDS = [];
	static OPTIONAL_FIELDS = ['course_id', 'course_name', 'visible'];

	constructor(params: ParseableCourse = {}) {
		super(params as Dictionary<generic>);
	}

	setDates(dates: Partial<CourseDates>) {
		if (dates.start != null){
			this.course_dates.start = dates.start;
		}
		if (dates.end != null){
			this.course_dates.end = dates.end;
		}
	}
}

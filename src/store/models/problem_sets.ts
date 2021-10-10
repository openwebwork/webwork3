/* These are Problem Set interfaces */

import { Dictionary, parseNonNegInt, parseBoolean } from '@/store/models';

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW',
	UNKNOWN = 'UNKNOWN'
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

export interface QuizDates extends DatesType {
	open: number;
	due: number;
	answer:number;
}

export interface QuizParams extends ParamsType {
	timed?: boolean;
	quiz_duration?: number;
}

export interface ReviewSetDates extends DatesType {
	open: number;
	closed: number;
}

export interface ReviewSetParams extends ParamsType {
	allow?: boolean;
}

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number;
	params?: Dictionary<string>;
	dates?: Dictionary<string>;
}

export class ProblemSet {
	set_id: number;
	set_name: string;
	course_id: number;
	set_type: ProblemSetType;
	set_visible: boolean;
	set_params: ParamsType;
	dates: DatesType;

	constructor(params?: ParseableProblemSet){
		this.set_id = params?.set_id ? parseNonNegInt(params?.set_id) : 0;
		this.set_name = params?.set_name ?? '';
		this.course_id = params?.course_id ? parseNonNegInt(params.course_id) : 0;
		const _set_visible = params?.set_visible ? parseBoolean(params?.set_visible) : false;
		this.set_visible = _set_visible ?? false;
		this.set_type = ProblemSetType.UNKNOWN;
		this.set_params = {};
		this.dates = {};
	}
}

export class Quiz extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.QUIZ;
		// parse the params
		const timed = params?.params?.timed ? parseBoolean(params?.params.timed) : false;
		this.set_params = {
			timed: timed ?? false,
			quiz_duration: params?.params?.quiz_duration ?
				parseNonNegInt(params?.params?.quiz_duration) :
				0
		};
		// parse the dates
		const _quiz_dates: QuizDates = {
			open: params?.dates?.open ? parseNonNegInt(params?.dates.open) : 0,
			due: params?.dates?.due ? parseNonNegInt(params?.dates.due) : 0,
			answer: params?.dates?.answer ? parseNonNegInt(params?.dates.answer) : 0,
		};
		this.dates = _quiz_dates;
	}
}

export class HomeworkSet extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.HW;
		// parse the params
		const rs = params?.params?.enable_reduced_scoring ?
			parseBoolean(params?.params.enable_reduced_scoring) : false;
		const hh = params?.params?.hide_hint ?
			parseBoolean(params?.params.hide_hint) : false;
		const _set_params: HomeworkSetParams = {
			enable_reduced_scoring: rs,
			hide_hint: hh,
			hardcopy_header: params?.params?.hardcopy_header ?? '',
			set_header: params?.params?.set_header ?? '',
			description: params?.params?.description ?? '',
		};
		this.set_params = _set_params;
		// parse the dates
		const _hw_dates: HomeworkSetDates = {
			open: params?.dates?.open ? parseNonNegInt(params?.dates.open) : 0,
			reduced_scoring: params?.dates?.reduced_scoring ?
				parseNonNegInt(params?.dates.reduced_scoring) : 0,
			due: params?.dates?.due ? parseNonNegInt(params?.dates.due) : 0,
			answer: params?.dates?.answer ? parseNonNegInt(params?.dates.answer) : 0,
		};
		this.dates = _hw_dates;
	}
}

export class ReviewSet extends ProblemSet {
	constructor(params?: ParseableProblemSet){
		super(params);
		this.set_type = ProblemSetType.REVIEW_SET;
		// parse the params

		// parse the dates
	}
}

export function parseProblemSet(set: ParseableProblemSet) {
	if (set.set_type == 'HW') {
		return new HomeworkSet(set);
	} else if (set.set_type == 'QUIZ') {
		return new Quiz(set);
	} else if (set.set_type === 'REVIEW') {
		return new ReviewSet(set);
	} else {
		throw `The problem set type '${set?.set_type || ''}' is not valid.'`;
	}
}

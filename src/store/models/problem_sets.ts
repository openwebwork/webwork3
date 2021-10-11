/* These are Problem Set interfaces */

import { Dictionary, parseNonNegInt, parseBoolean, Model, ParseError } from '@/store/models';
import { isUndefined } from 'lodash';

// const problem_set_types = [/hw/i, /quiz/i, /review/i];

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW',
	UNKNOWN = 'UNKNOWN'
}

function parseProblemSetType(type: string) {
	if (/hw/i.test(type)) {
		return ProblemSetType.HW;
	} else if (/quiz/i.test(type)) {
		return ProblemSetType.QUIZ;
	} else if (/review/i.test(type)) {
		return ProblemSetType.REVIEW_SET;
	}
	throw new ParseError('ProblemSetType', `The problem set type '${type}' is not valid.`);
}

// Homework Set interfaces

export interface ParseableHWDates {
	open?: number;
	reduced_scoring?: number;
	due?: number;
	answer?: number;
}

export interface ParseableHWParams {
	enable_reduced_scoring?: boolean|string|number;
	hide_hint?: boolean|string|number;
	hardcopy_header?: string;
	set_header?: string;
	description?: string;
}

export interface HomeworkSetParams {
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

// Quiz interfaces

export interface ParseableQuizDates {
	open?: number|string;
	due?: number|string;
	answer?: number|string;
}

export interface QuizDates {
	open: number;
	due: number;
	answer:number;
}

export interface ParseableQuizParams {
	timed?: boolean|string|number;
	quiz_duration?: number|string;
}

export interface QuizParams  {
	timed?: boolean;
	quiz_duration?: number;
}

// ReviewSet interfaces

export interface ParseableReviewParams {
	allow?: boolean|string|number;
}

export interface ReviewSetParams {
	allow?: boolean;
}

export interface ParseableReviewDates {
	open?: number|string;
	closed?: number|string;
}

export interface ReviewSetDates {
	open: number;
	closed: number;
}

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_params?: ParseableHWParams|ParseableQuizParams|ParseableReviewParams;
	set_dates?: ParseableHWDates|ParseableQuizDates|ParseableReviewDates;
}

export interface ParseableHWSet extends ParseableProblemSet {
	set_params: ParseableHWParams;
	set_dates: HomeworkSetDates;
}

export class ProblemSet extends Model {
	set_id: number;
	set_name?: string;
	course_id: number;
	set_type: ProblemSetType;
	set_visible: boolean;
	set_params?: HomeworkSetParams|QuizParams|ReviewSetParams;
	set_dates?: HomeworkSetDates|QuizDates|ReviewSetDates;

	static REQUIRED_FIELDS = ['set_type'];
	static OPTIONAL_FIELDS = ['set_id', 'set_name', 'course_id', 'set_visible', 'set_params', 'set_dates'];

	get required_fields() {
		return (this._required_fields?.length==0) ? ProblemSet.REQUIRED_FIELDS : [];
	}

	get all_fields() {
		return [...ProblemSet.REQUIRED_FIELDS, ...ProblemSet.OPTIONAL_FIELDS];
	}

	static get ALL_FIELDS() {
		return [...ProblemSet.REQUIRED_FIELDS, ...ProblemSet.OPTIONAL_FIELDS];
	}

	constructor(params: ParseableProblemSet = {}) {
		super(params as Dictionary<string|number|boolean>);
		this.set_id = 0;
		this.course_id = 0;
		this.set_type = ProblemSetType.UNKNOWN;
		this.set_visible = false;
		this.setBaseParams(params);
	}

	setBaseParams(params: ParseableProblemSet) {
		if (!isUndefined(params.set_id)) {
			this.set_id = parseNonNegInt(params.set_id);
		}
		if (!isUndefined(params.course_id)) {
			this.course_id = parseNonNegInt(params.course_id);
		}
		if (!isUndefined(params.set_name)) {
			this.set_name = params.set_name;
		}
		if (!isUndefined(params.set_visible)) {
			this.set_visible = parseBoolean(params.set_visible);
		}
		if (!isUndefined(params.set_type)) {
			this.set_type = parseProblemSetType(params.set_type);
		}
	}

	validate() {
		throw 'You must override the validate() method';
	}
}

export class Quiz extends ProblemSet {
	set_params: QuizParams;
	set_dates: QuizDates;
	constructor(params: ParseableProblemSet = {}){
		params.set_type = 'QUIZ';
		super(params);
		this.set_dates = {
			open: 0,
			due: 0,
			answer: 0
		};
		this.set_params = {};
		// parse the params
		this.set(params);
	}

	set(params: ParseableProblemSet) {
		super.setBaseParams(params);
		this.setParams(params.set_params as ParseableQuizParams);
		this.setDates(params.set_dates as ParseableQuizDates);
	}

	setParams(quiz_params: ParseableQuizParams) {
		const _set_params: QuizParams = {};
		if (!isUndefined(quiz_params.timed)) {
			_set_params.timed = parseBoolean(quiz_params.timed);
		}
		if (!isUndefined(quiz_params.quiz_duration)) {
			_set_params.quiz_duration = parseNonNegInt(quiz_params.quiz_duration);
		}
		this.set_params = _set_params;
	}

	setDates(quiz_dates: ParseableQuizDates) {
		this.set_dates =  {
			open: parseNonNegInt(quiz_dates.open ?? 0),
			due: parseNonNegInt(quiz_dates.due ?? 0),
			answer: parseNonNegInt(quiz_dates.answer ?? 0)
		};
	}

	validate() {
		return this.set_dates.open <= this.set_dates.due &&
			this.set_dates.due <= this.set_dates.answer;
	}
}

export class HomeworkSet extends ProblemSet {
	set_params: HomeworkSetParams;
	set_dates: HomeworkSetDates;
	constructor(params: ParseableProblemSet = {}) {
		params.set_type = 'HW';
		super(params);
		this.set_dates = {
			open: 0,
			reduced_scoring: 0,
			due: 0,
			answer: 0
		};
		this.set_params = {};
		this.set(params);
	}

	set(params: ParseableProblemSet) {
		super.setBaseParams(params);
		this.setParams(params.set_params as ParseableHWParams);
		this.setDates(params.set_dates as ParseableHWDates);
	}

	setParams(hw_params: ParseableHWParams = {}) {
		// parse the params
		const _set_params: HomeworkSetParams = {};
		if (!isUndefined(hw_params.enable_reduced_scoring)) {
			_set_params.enable_reduced_scoring = parseBoolean(hw_params.enable_reduced_scoring);
		}
		if (!isUndefined(hw_params.hide_hint)) {
			_set_params.hide_hint = parseBoolean(hw_params.hide_hint);
		}
		if (!isUndefined(hw_params.hardcopy_header)) {
			_set_params.hardcopy_header = hw_params.hardcopy_header;
		}
		if (!isUndefined(hw_params.set_header)) {
			_set_params.set_header = hw_params.set_header;
		}
		if (!isUndefined(hw_params.description)) {
			_set_params.description = hw_params.description;
		}
		this.set_params = _set_params;
	}

	setDates(hw_dates: ParseableHWDates = {}) {
		// parse the dates
		this.set_dates = {
			open: parseNonNegInt(hw_dates.open ?? 0),
			reduced_scoring: parseNonNegInt(hw_dates.reduced_scoring ?? 0),
			due: parseNonNegInt(hw_dates.due ?? 0),
			answer: parseNonNegInt(hw_dates.answer ?? 0)
		};
	}

	validate() {
		const params = this.set_params;
		const dates = this.set_dates;
		if (params.enable_reduced_scoring) {
			if (!isUndefined(dates.open) && !isUndefined(dates.reduced_scoring) &&
				!isUndefined(dates.due) && !isUndefined(dates.answer)) {
				return dates.open <= dates.reduced_scoring &&
						dates.reduced_scoring <= dates.due && dates.due <= dates.answer;
			}
		} else {
			if (!isUndefined(dates.open) &&
			!isUndefined(dates.due) && !isUndefined(dates.answer)) {
				return dates.open <= dates.due && dates.due <= dates.answer;
			}
		}
		return false;
	}
}

export class ReviewSet extends ProblemSet {
	constructor(params: ParseableProblemSet = {}){
		params.set_type = 'REVIEW';
		super(params);
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

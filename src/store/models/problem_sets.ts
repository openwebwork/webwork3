/* These are Problem Set interfaces */

import { Dictionary, parseNonNegInt, parseBoolean, Model, ParseError, generic,
	InvalidFieldsException, ParseableModel } from '@/store/models';
import { difference } from 'lodash';

// const problem_set_types = [/hw/i, /quiz/i, /review/i];

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW',
	UNKNOWN = 'UNKNOWN'
}

export function parseProblemSetType(type: string) {
	if (/hw/i.test(type)) {
		return ProblemSetType.HW;
	} else if (/quiz/i.test(type)) {
		return ProblemSetType.QUIZ;
	} else if (/review/i.test(type)) {
		return ProblemSetType.REVIEW_SET;
	}
	throw new ParseError('ProblemSetType', `The problem set type '${type}' is not valid.`);
}

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_params?: ParseableHWParams|ParseableQuizParams|ParseableReviewParams;
	// set_params?: Dictionary<generic>;
	set_dates?: ParseableHWDates|ParseableQuizDates|ParseableReviewDates;
}

export class ProblemSet extends Model(
	['set_visible'], ['set_id', 'course_id'], ['set_type', 'set_name'],
	['set_params', 'set_dates'],
	{
		set_type: { field_type: 'string', default_value: 'UNKNOWN' },
		set_id: { field_type: 'non_neg_int', default_value: 0 },
		set_name: { field_type: 'string' },
		course_id: { field_type: 'non_neg_int', default_value: 0 },
		set_visible: { field_type: 'boolean', default_value: false },
	}) {
	static REQUIRED_FIELDS = ['set_type'];
	static OPTIONAL_FIELDS = ['set_id', 'set_name', 'course_id', 'set_visible'];

	_date_fields: Array<string> = [];
	set_params = {};
	set_dates = {};

	constructor(params: ParseableProblemSet = {}) {
		super(params as ParseableModel);
	}

	isValid() {
		throw 'You must override the isValid() method';
	}

	setDates(dates: Dictionary<generic>){
		// check that only valid dates are present
		const invalid_dates = difference(Object.keys(dates), this._date_fields);
		if (invalid_dates.length !== 0) {
			throw new InvalidFieldsException('_all',
				`The dates(s) '${invalid_dates.join(', ')}' are not valid for ${this.constructor.name}.`);
		}

		/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-member-access,
		  @typescript-eslint/no-explicit-any */
		Object.keys(dates).forEach(key => {
			if (dates != null) {
				(this.set_dates as any)[key] = parseNonNegInt((dates as any)[key]);
			}
		});
		// eslint-enable
	}
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

export interface QuizParams {
	timed?: boolean;
	quiz_duration?: number;
}

export class Quiz extends ProblemSet {
	set_params: QuizParams = {};
	set_dates: QuizDates = {
		open: 0,
		due: 0,
		answer: 0
	};
	_date_fields = ['open', 'due', 'answer'];

	constructor(params: ParseableProblemSet = {}) {
		super(params as ParseableModel);
		params.set_type = 'QUIZ';
		this.set(params as ParseableModel);
	}

	setParams(quiz_params: ParseableQuizParams) {
		if (quiz_params.timed != null) {
			this.set_params.timed = parseBoolean(quiz_params.timed);
		}
		if (quiz_params.quiz_duration != null) {
			this.set_params.quiz_duration = parseNonNegInt(quiz_params.quiz_duration);
		}
	}

	setDates(hw_dates: ParseableQuizDates = {}) {
		// parse the dates
		this.set_dates = {
			open: parseNonNegInt(hw_dates.open ?? 0),
			due: parseNonNegInt(hw_dates.due ?? 0),
			answer: parseNonNegInt(hw_dates.answer ?? 0)
		};
	}

	isValid() {
		return this.set_dates.open <= this.set_dates.due && this.set_dates.due <= this.set_dates.answer;
	}
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

export interface ParseableHWSet {
	set_params: ParseableHWParams;
	set_dates: ParseableHWDates;
}

export class HomeworkSet extends ProblemSet {
	set_params: HomeworkSetParams;
	set_dates: HomeworkSetDates;
	constructor(params: ParseableProblemSet = {}) {
		params.set_type = 'HW';
		super(params as ParseableModel);
		this.set_dates = {
			open: 0,
			reduced_scoring: 0,
			due: 0,
			answer: 0
		};
		this.set_params = {};
		this.set(params as ParseableModel);
	}

	setParams(hw_params: ParseableHWParams = {}) {
		// parse the params
		if (hw_params.enable_reduced_scoring != null) {
			this.set_params.enable_reduced_scoring = parseBoolean(hw_params.enable_reduced_scoring);
		}
		if (hw_params.hide_hint != null) {
			this.set_params.hide_hint = parseBoolean(hw_params.hide_hint);
		}
		if (hw_params.hardcopy_header != null) {
			this.set_params.hardcopy_header = hw_params.hardcopy_header;
		}
		if (hw_params.set_header != null) {
			this.set_params.set_header = hw_params.set_header;
		}
		if (hw_params.description != null) {
			this.set_params.description = hw_params.description;
		}
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

	isValid() {
		const params = this.set_params;
		const dates = this.set_dates;
		if (params.enable_reduced_scoring) {
			if (dates.open != null && dates.reduced_scoring != null && dates.due != null && dates.answer != null) {
				return dates.open <= dates.reduced_scoring &&
						dates.reduced_scoring <= dates.due && dates.due <= dates.answer;
			}
		} else {
			if (dates.open != null  && dates.due != null && dates.answer != null) {
				return dates.open <= dates.due && dates.due <= dates.answer;
			}
		}
		return false;
	}
}

// ReviewSet interfaces

export interface ParseableReviewParams extends Dictionary<generic|undefined> {
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

export class ReviewSet extends ProblemSet {
	constructor(params: ParseableProblemSet = {}){
		params.set_type = 'REVIEW';
		super(params as ParseableModel);
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

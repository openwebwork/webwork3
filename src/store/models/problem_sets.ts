/* These are Problem Set interfaces */

import { Dictionary, parseNonNegInt, Model, ParseError, generic,
	InvalidFieldsException, ParseableModel, ModelField, parseParams } from 'src/store/models/index';
import { difference } from 'lodash';
import { Problem } from './set_problem';

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

type ProblemSetParams = ParseableHWParams | ParseableQuizParams | ParseableReviewParams;
type ProblemSetDates = ParseableHWDates | ParseableQuizDates | ParseableReviewDates;

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_version?: string | number;
	set_params?: ProblemSetParams;
	// set_params?: Dictionary<generic>;
	set_dates?: ProblemSetDates;
	problems?: Array<Problem>;
}

export class ProblemSet extends Model(
	['set_visible'], ['set_id', 'course_id', 'set_version'], ['set_type', 'set_name'],
	['set_params', 'set_dates'],
	{
		set_type: { field_type: 'string', default_value: 'UNKNOWN' },
		set_id: { field_type: 'non_neg_int', default_value: 0 },
		set_version: { field_type: 'non_neg_int', default_value: 1 },
		set_name: { field_type: 'string' },
		course_id: { field_type: 'non_neg_int', default_value: 0 },
		set_visible: { field_type: 'boolean', default_value: false },
		problems: { field_type: 'array', default_value: [] }
	}) {

	static REQUIRED_FIELDS = ['set_type'];
	static OPTIONAL_FIELDS = ['set_id', 'set_name', 'course_id', 'set_visible', 'problems'];

	static ALL_FIELDS = [...ProblemSet.REQUIRED_FIELDS, ...ProblemSet.OPTIONAL_FIELDS,
		...['set_params', 'set_dates', 'problems']];

	_date_fields: Array<string> = [];
	_param_fields: ModelField = {};
	set_params = {};
	set_dates = {};

	constructor(params: ParseableProblemSet = {}) {
		super(params as ParseableModel);
	}

	isValid() {
		throw 'You must override the isValid() method';
	}

	setDates(dates: Dictionary<generic> = {}){
		// check that only valid dates are present
		const invalid_dates = difference(Object.keys(dates), this._date_fields);
		if (invalid_dates.length !== 0) {
			throw new InvalidFieldsException('_all',
				`The dates(s) '${invalid_dates.join(', ')}' are not valid for ${this.constructor.name}.`);
		}

		/* eslint-disable @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call,
		  @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment */
		Object.keys(dates).forEach(key => {
			(this.set_dates as any)[key] = parseNonNegInt((dates as any)[key]);
		});
		/* eslint-enable */
	}

	setParams(params: Dictionary<generic> = {}) {
		this.set_params = parseParams(params, this._param_fields);
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
	set_dates: QuizDates;
	set_params: QuizParams;
	constructor(params: ParseableProblemSet = {}) {
		params.set_type = 'QUIZ';
		super(params as ParseableModel);
		this._date_fields = ['open', 'due', 'answer'];
		this._param_fields = {
			timed: {
				field_type: 'boolean'
			},
			quiz_duration: {
				field_type: 'non_neg_int'
			}
		};
		this.set_dates = {
			open: 0,
			due: 0,
			answer:0
		};
		if (params.set_dates) {
			this.setDates(params.set_dates as Dictionary<generic>);
		}
		this.set_params = {};
		if (params.set_params) {
			this.setParams(params.set_params as Dictionary<generic>);
		}
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
		this._date_fields = ['open', 'reduced_scoring', 'due', 'answer'];

		this._param_fields = {
			enable_reduced_scoring: {
				field_type: 'boolean',
				default_value: false
			},
			hide_hint: {
				field_type: 'boolean'
			},
			hardcopy_header: {
				field_type: 'string'
			},
			set_header: {
				field_type: 'string'
			},
			description: {
				field_type: 'string'
			}
		};
		this.set_dates = {
			open: 0,
			reduced_scoring: 0,
			due: 0,
			answer:0
		};
		this.setDates(params.set_dates as Dictionary<generic>);
		this.set_params = {};
		this.setParams(params.set_params as Dictionary<generic>);
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
	set_params: ReviewSetParams;
	set_dates: ReviewSetDates;

	constructor(params: ParseableProblemSet = {}){
		params.set_type = 'REVIEW';
		super(params as ParseableModel);
		this._date_fields = ['open', 'closed'];

		this.set_dates = {
			open: 0,
			closed: 0
		};
		this.setDates(params.set_dates as Dictionary<generic>);
		this.set_params = {};
		this.setParams(params.set_params as Dictionary<generic>);
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

export interface ParseableUserSet {
	user_set_id?: number | string;
	set_id?: number | string;
	course_user_id?: number | string;
	set_version?: number | string;
	set_params?: Dictionary<generic>;
	set_dates?: Dictionary<generic>;
}

export class UserSet extends Model(
	[], ['user_set_id', 'set_id', 'course_user_id', 'set_version'], [],
	['set_dates', 'set_params'], {
		user_set_id: { field_type: 'non_neg_int' },
		set_id: { field_type: 'non_neg_int' },
		course_user_id: { field_type: 'non_neg_int' },
		set_version: { field_type: 'non_neg_int' }
	}) {

	static ALL_FIELDS = ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'set_dates', 'set_params'];

	constructor(params: ParseableUserSet = {}) {
		super(params as ParseableModel);
		this.set_dates = params.set_dates ?? {};
		this.set_params = params.set_params ?? {};

	}

	isValid() { // check the dates are valid
		const d = this.set_dates;
		if (d && d.open && d.reduced_scoring && d.due && d.answer) {
			return d.open <= d.reduced_scoring && d.reduced_scoring <= d.due && d.due <= d.answer;
		} else if (d && d.open && d.due && d.answer) {
			return d.open <= d.due && d.due <= d.answer;
		} else if (d && d.open && d.closed) {
			return d.open <= d.closed;
		}
		return false;
	}
}

export type ParseableMergedUserSet = ParseableProblemSet & ParseableUserSet;

// ['set_visible'], ['set_id', 'course_id'], ['set_type', 'set_name'],
// ['set_params', 'set_dates']

export class MergedUserSet extends Model(
	['set_visible'], ['user_set_id', 'set_id', 'course_user_id', 'set_version', 'course_id'],
	['set_type', 'set_name', 'username'], ['set_dates', 'set_params'],
	{
		set_visible: { field_type: 'boolean', default_value: false },
		user_set_id: { field_type: 'non_neg_int' },
		set_id: { field_type: 'non_neg_int' },
		course_user_id: { field_type: 'non_neg_int' },
		course_id: { field_type: 'non_neg_int' },
		set_version: { field_type: 'non_neg_int' },
		set_type: { field_type: 'string' },
		set_name: { field_type: 'string' },
		username: { field_type: 'username' }
	}
	 ) {

	set_params = {};
	set_dates = {};

	constructor(params: ParseableMergedUserSet = {}) {
		super(params as ParseableModel);
		this.set_dates = params.set_dates ?? {};
		this.set_params = params.set_params ?? {};
	}

}

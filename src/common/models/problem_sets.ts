/* These are Problem Set interfaces */

import { logger } from 'src/boot/logger';
import { Model } from '.';
import { parseBoolean, ParseError, parseNonNegInt } from './parsers';

export enum ProblemSetType {
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW_SET = 'REVIEW',
	UNKNOWN = 'UNKNOWN'
}

/**
 * This takes in a general problem set and returns the specific subclassed ProblemSet
 * @param problem ParseableProblemSet
 * @returns HomeworkSet, Quiz or ReviewSet
 */

export function parseProblemSet(set: ParseableProblemSet) {
	if (/hw/i.test(set.set_type ?? '')) {
		return new HomeworkSet(set as ParseableHomeworkSet);
	} else if (/quiz/i.test(set.set_type ?? '')) {
		return new Quiz(set as ParseableQuiz);
	} else if (/review/i.test(set.set_type ?? '')) {
		return new ReviewSet(set as ParseableReviewSet);
	}

	throw new ParseError('ProblemSetType', `The problem set type '${set.set_type ?? ''}' is not valid.`);
}

export type ProblemSetParams = HomeworkSetParams | QuizParams | ReviewSetParams;
export type ProblemSetDates = HomeworkSetDates | QuizDates | ReviewSetDates;

/* Problem Set (HomeworkSet, Quiz, ReviewSet ) classes */

export interface ParseableProblemSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_params?: ProblemSetParams;
	set_dates?: ProblemSetDates;
}

export class ProblemSet extends Model {
	private _set_id = 0;
	private _set_visible = false;
	private _course_id = 0;
	protected _set_type: ProblemSetType = ProblemSetType.UNKNOWN;
	private _set_name = '';

	constructor(params: ParseableProblemSet = {}) {
		super();
		this.set(params);
	}

	static ALL_FIELDS = ['set_id', 'set_visible', 'course_id', 'set_type', 'set_name', 'set_params', 'set_dates'];

	get all_field_names(): string[] {
		return ProblemSet.ALL_FIELDS;
	}

	get param_fields(): string[] {
		return ['set_dates', 'set_params'];
	}

	set(params: ParseableProblemSet) {
		if (params.set_id != undefined) this.set_id = params.set_id;
		if (params.set_visible != undefined) this.set_visible = params.set_visible;
		if (params.course_id != undefined) this.course_id = params.course_id;
		if (params.set_type != undefined) this.set_type = params.set_type;
		if (params.set_name != undefined) this.set_name = params.set_name;
	}

	public get set_id(): number { return this._set_id;}
	public set set_id(value: number | string) { this._set_id = parseNonNegInt(value);}

	public get course_id(): number { return this._course_id;}
	public set course_id(value: number | string) { this._course_id = parseNonNegInt(value);}

	public get set_visible() : boolean { return this._set_visible;}
	public set set_visible(value: number | string | boolean) { this._set_visible = parseBoolean(value);}

	public get set_type(): ProblemSetType { return this._set_type; }
	public set set_type(value: string) {
		if (value === 'HW') { this._set_type = ProblemSetType.HW;}
		else if (value === 'QUIZ') { this._set_type = ProblemSetType.QUIZ;}
		else if (value === 'REVIEW') { this._set_type = ProblemSetType.REVIEW_SET;}
		else { this._set_type = ProblemSetType.UNKNOWN; }
	}

	public get set_name() : string { return this._set_name;}
	public set set_name(value: string) { this._set_name = value;}

	public get set_params(): ProblemSetParams {
		throw 'The subclass must override set_params();';
	}

	public get set_dates(): ProblemSetDates {
		throw 'The subclass must override set_dates();';
	}

	hasValidDates() {
		throw 'The hasValidDates() method must be overridden.';
	}
}

// Quiz interfaces

export interface ParseableQuizDates {
	open?: number | string;
	due?: number | string;
	answer?: number | string;
}

export class QuizDates extends Model {
	private _open = 0;
	private _due = 0;
	private _answer = 0;

	constructor(params: ParseableQuizDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableQuizDates) {
		if (params.open != undefined) this.open = params.open;
		if (params.due != undefined) this.due = params.due;
		if (params.answer != undefined) this.answer = params.answer;
	}

	get all_field_names(): string[] {
		return ['open', 'due', 'answer'];
	}
	get param_fields(): string[] { return [];}

	public get open(): number { return this._open;}
	public set open(value: number | string) { this._open = parseNonNegInt(value);}

	public get due(): number { return this._due;}
	public set due(value: number | string) { this._due = parseNonNegInt(value);}

	public get answer() : number { return this._answer;}
	public set answer(value: number | string) { this._answer = parseNonNegInt(value);}

	public isValid() {
		return this.open <= this.due && this.due <= this.answer;
	}

	public clone() {
		return new QuizDates(this.toObject());
	}

}

export interface ParseableQuizParams {
	timed?: boolean | string | number;
	quiz_duration?: number | string;
}

export class QuizParams extends Model {
	private _timed = false;
	private _quiz_duration = 0;

	constructor(params: ParseableQuizParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableQuizParams) {
		if (params.timed != undefined) this.timed = params.timed;
		if (params.quiz_duration != undefined) this.quiz_duration = params.quiz_duration;
	}

	get all_field_names(): string[] {
		return ['timed', 'quiz_duration'];
	}
	get param_fields(): string[] { return [];}

	public get timed() : boolean { return this._timed;}
	public set timed(value: number | string | boolean) { this._timed = parseBoolean(value);}

	public get quiz_duration(): number { return this._quiz_duration;}
	public set quiz_duration(value: number | string) { this._quiz_duration = parseNonNegInt(value);}

}

export interface ParseableQuiz {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_version?: string | number;
	set_params?: ParseableQuizParams;
	set_dates?: ParseableQuizDates;
}

export class Quiz extends ProblemSet {
	private _set_params = new QuizParams();
	private _set_dates = new QuizDates();
	constructor(params: ParseableQuiz = {}) {
		super(params as ParseableProblemSet);
		this._set_type = ProblemSetType.QUIZ;
		if (params.set_params) this.set_params.set(params.set_params);
		if (params.set_dates) this.set_dates.set(params.set_dates);
	}

	public get set_dates() { return this._set_dates; }
	public get set_params() { return this._set_params; }

	public hasValidDates() {
		return this.set_dates.isValid();
	}

	clone() {
		return new Quiz(this.toObject());
	}

}

/**
 * HomeworkSet
 */

export interface ParseableHomeworkSetParams {
	enable_reduced_scoring?: boolean | string | number;
}

export class HomeworkSetParams extends Model {
	private _enable_reduced_scoring = false;

	constructor(params: ParseableHomeworkSetParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableHomeworkSetParams) {
		if (params.enable_reduced_scoring != undefined) this.enable_reduced_scoring = params.enable_reduced_scoring;
	}

	get all_field_names(): string[] {
		return ['enable_reduced_scoring'];
	}
	get param_fields(): string[] { return [];}

	public get enable_reduced_scoring() : boolean { return this._enable_reduced_scoring;}
	public set enable_reduced_scoring(value: number | string | boolean) {
		this._enable_reduced_scoring = parseBoolean(value);
	}

}

export interface ParseableHomeworkSetDates {
	open?: number | string;
	due?: number | string;
	reduced_scoring?: number | string;
	answer?: number | string;
}

export class HomeworkSetDates extends Model {
	private _open = 0;
	private _due = 0;
	private _reduced_scoring = 0;
	private _answer = 0;

	constructor(params: ParseableHomeworkSetDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableHomeworkSetDates) {
		if (params.open != undefined) this.open = params.open;
		if (params.due != undefined) this.due = params.due;
		if (params.reduced_scoring != undefined) this.reduced_scoring = params.reduced_scoring;
		if (params.answer != undefined) this.answer = params.answer;
	}

	get all_field_names(): string[] {
		return ['open', 'due', 'reduced_scoring', 'answer'];
	}
	get param_fields(): string[] { return [];}

	public get open(): number { return this._open;}
	public set open(value: number | string) { this._open = parseNonNegInt(value);}

	public get reduced_scoring(): number { return this._reduced_scoring;}
	public set reduced_scoring(value: number | string) { this._reduced_scoring = parseNonNegInt(value);}

	public get due(): number { return this._due;}
	public set due(value: number | string) { this._due = parseNonNegInt(value);}

	public get answer() : number { return this._answer;}
	public set answer(value: number | string) { this._answer = parseNonNegInt(value);}

	public isValid(params: { enable_reduced_scoring: boolean; }) {
		return params.enable_reduced_scoring ?
			this.open <= this.reduced_scoring && this.reduced_scoring <= this.due && this.due <= this.answer :
			this.open <= this.due && this.due <= this.answer;
	}

	public clone() {
		return new HomeworkSetDates(this.toObject());
	}
}

export interface ParseableHomeworkSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_version?: string | number;
	set_params?: ParseableHomeworkSetParams;
	set_dates?: ParseableHomeworkSetDates;
}

export class HomeworkSet extends ProblemSet {
	private _set_params = new HomeworkSetParams();
	private _set_dates = new HomeworkSetDates();
	constructor(params: ParseableHomeworkSet = {}) {
		super(params as ParseableProblemSet);
		this._set_type = ProblemSetType.HW;
		if (params.set_params) this.set_params.set(params.set_params);
		if (params.set_dates) this.set_dates.set(params.set_dates);
	}

	hasValidDates(): boolean {
		return this.set_dates.isValid({ enable_reduced_scoring: this.set_params.enable_reduced_scoring });
	}

	public get set_dates() { return this._set_dates; }
	public get set_params() { return this._set_params; }

	clone() {
		return new HomeworkSet(this.toObject());
	}

}

/**
 * ReviewSet
 */

export interface ParseableReviewSetParams {
	test_param?: boolean | string | number;
}

export class ReviewSetParams extends Model {
	private _test_param = false;

	constructor(params: ParseableReviewSetParams = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableReviewSetParams) {
		if (params.test_param != undefined) this.test_param = params.test_param;
	}

	get all_field_names(): string[] {
		return ['test_param'];
	}
	get param_fields(): string[] { return [];}

	public get test_param() : boolean { return this._test_param;}
	public set test_param(value: number | string | boolean) {
		this._test_param = parseBoolean(value);
	}

}

export interface ParseableReviewSetDates {
	open?: number | string;
	closed?: number | string;
}

export class ReviewSetDates extends Model {
	private _open = 0;
	private _closed = 0;

	constructor(params: ParseableReviewSetDates = {}) {
		super();
		this.set(params);
	}

	set(params: ParseableReviewSetDates) {
		if (params.open != undefined) this.open = params.open;
		if (params.closed != undefined) this.closed = params.closed;
	}

	get all_field_names(): string[] {
		return ['open', 'closed'];
	}
	get param_fields(): string[] { return [];}

	public get open(): number { return this._open;}
	public set open(value: number | string) { this._open = parseNonNegInt(value);}

	public get closed(): number { return this._closed;}
	public set closed(value: number | string) { this._closed = parseNonNegInt(value);}

	public isValid() {
		return this.open <= this.closed;
	}

	public clone() {
		return new ReviewSetDates(this.toObject());
	}
}

export interface ParseableReviewSet {
	set_id?: string | number;
	set_name?: string;
	course_id?: string | number;
	set_type?: string;
	set_visible?: string | number | boolean;
	set_version?: string | number;
	set_params?: ParseableReviewSetParams;
	set_dates?: ParseableReviewSetDates;
}

export class ReviewSet extends ProblemSet {
	private _set_params = new ReviewSetParams();
	private _set_dates = new ReviewSetDates();
	constructor(params: ParseableReviewSet = {}) {
		super(params as ParseableProblemSet);
		this._set_type = ProblemSetType.REVIEW_SET;
		if (params.set_params) this.set_params.set(params.set_params);
		if (params.set_dates) this.set_dates.set(params.set_dates);
	}

	hasValidDates(): boolean {
		return this.set_dates.isValid();
	}

	public get set_dates() { return this._set_dates; }
	public get set_params() { return this._set_params; }

	clone() {
		return new ReviewSet(this.toObject());
	}

}

/**
 * This function takes in a ProblemSet and a ProblemSetType,
 * returning a new ProblemSet of the requested type
 * @param set ProblemSet
 * @param set_type ProblemSetType
 * @returns HomeworkSet | Quiz | ReviewSet
 */

export function convertSet(old_set: ProblemSet, new_set_type: ProblemSetType) {
	if (old_set.set_type === new_set_type) return old_set;

	const new_set_params = old_set.toObject();
	delete new_set_params.set_params;
	delete new_set_params.set_dates;

	// pull dates from old_set
	const open = old_set.set_dates.open;
	let reduced = 0, due = 0, answer = 0;
	switch (old_set.set_type) {
	case 'HW':
		reduced = (old_set as HomeworkSet).set_dates.reduced_scoring;
		due = (old_set as HomeworkSet).set_dates.due;
		answer = (old_set as HomeworkSet).set_dates.answer;
		break;
	case 'QUIZ':
		reduced = due = (old_set as Quiz).set_dates.due;
		answer = (old_set as Quiz).set_dates.answer;
		break;
	case 'REVIEW':
		reduced = due = answer = (old_set as ReviewSet).set_dates.closed;
		break;
	default:
		throw new ParseError('ProblemSetType', `convertSet does not support incoming ${old_set.set_type} sets.`);
	}

	// create new_set with new_set_type and set dates
	let new_set: HomeworkSet | Quiz | ReviewSet;
	switch (new_set_type) {
	case 'HW':
		new_set = new HomeworkSet(new_set_params);
		new_set.set_dates.set({ open, reduced_scoring: reduced, due, answer });
		break;
	case 'QUIZ':
		new_set = new Quiz(new_set_params);
		new_set.set_dates.set({ open, due, answer });
		break;
	case 'REVIEW':
		new_set = new ReviewSet(new_set_params);
		new_set.set_dates.set({ open, closed: due });
		break;
	default:
		throw new ParseError('ProblemSetType', `convertSet does not support conversion to ${new_set_type || 'EMPTY'}`);
	}

	if (!new_set.hasValidDates()) logger.error('[problem_sets/convertSet] corrupt dates in conversion of set, TSNH?');
	return new_set;
}

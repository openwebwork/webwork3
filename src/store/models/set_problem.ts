
/* These are Problem interfaces */

import { RendererRequest } from '@/APIRequests/renderer';
import { logger } from '@/boot/logger';
import { Dictionary, Model, generic, ParseableModel, ModelField, parseParams } from '@/store/models/index';
import { random } from 'lodash';

export enum ProblemType {
	SET = 'SET',
	LIBRARY = 'LIBRARY',
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW = 'REVIEW',
}

export const DEFAULT_LIBRARY_SEED = 1234;

type ProblemParams = SetProblemParams;

/* Problem class */

export interface ParseableProblem {
	problem_id?: string | number;
	set_id?: string | number;
	seed?: string | number;
	id?: string | number; // library_id from OPLv3
	problem_number?: string | number;
	problem_version?: string | number;
	problem_params?: ProblemParams;
}

export interface SetProblemParams {
	problem_path?: string;
	library_id?: string | number;
	weight?: number;
}

export interface LibraryParams {
	id?: number;
	file_path?: string;
}

export class Problem extends Model(
	['show_hints', 'show_solutions', 'show_preview_button', 'show_check_answers_button', 'show_correct_answers_button'],
	['problem_id', 'set_id', 'seed', 'id', 'problem_number', 'problem_version', 'permission_level'],
	['output_format', 'answer_prefix'],
	['problem_params'],
	{
		problem_id: { field_type: 'non_neg_int', default_value: 0 },
		set_id: { field_type: 'non_neg_int', default_value: 0 },
		seed: { field_type: 'non_neg_int', default_value: 0 },
		id: { field_type: 'non_neg_int', default_value: 0 },
		problem_number: { field_type: 'non_neg_int', default_value: 0 },
		problem_version: { field_type: 'non_neg_int', default_value: 0 },
		permission_level: { field_type: 'non_neg_int', default_value: 0 },
		output_format: { field_type: 'string', default_value: 'ww3' },
		answer_prefix: { field_type: 'string', default_value: '' },
		show_hints: { field_type: 'boolean', default_value: false },
		show_solutions: { field_type: 'boolean', default_value: false },
		// TODO: drop the button booleans
		show_preview_button: { field_type: 'boolean', default_value: false },
		show_check_answers_button: { field_type: 'boolean', default_value: false },
		show_correct_answers_button: { field_type: 'boolean', default_value: false }
	}) {
	static REQUIRED_FIELDS = ['seed', 'output_format'];
	static OPTIONAL_FIELDS = ['problem_id', 'set_id', 'seed', 'id', 'problem_number', 'problem_version'];

	problem_type = '';
	_param_fields: ModelField = {};
	problem_params = {};

	constructor(params: ParseableProblem = {}) {
		super(params as ParseableModel);
	}

	setParams(params: Dictionary<generic> = {}) {
		this.problem_params = parseParams(params, this._param_fields);
	}

	isValid() {
		throw 'You must override the isValid() method';
	}

	// override this for problem-types which may be re-randomized
	rerandomize() {
		throw 'This problem may not be re-randomized.';
	}

	// facade for library/set/assigned problems
	path(): string {
		throw 'Subclass has not defined the source path';
	}

	// return the RendererRequest params for this Problem
	requestParams(): RendererRequest {
		if (this.seed === undefined) throw 'Cannot generate requestParams for problem because there is no seed value.';
		if (this.output_format === undefined) {
			throw 'Cannot generate requestParams for problem because there is no output format';
		}
		return {
			problemSeed: this.seed,
			outputFormat: this.output_format,
			sourceFilePath: this.path(), // will this respect inheritance?
			problemNumber: this.problem_number,
			answerPrefix: this.answer_prefix,
			permissionLevel: this.permission_level,
			language: 'en',
			showHints: this.show_hints,
			showSolutions: this.show_solutions,
			showPreviewButton: this.show_preview_button,
			showCheckAnswersButton: this.show_check_answers_button,
			showCorrectAnswersButton: this.show_correct_answers_button,
		};
	}
}

// problems to be rendered for sets editor
export class SetProblem extends Problem {
	constructor(params: ParseableProblem = {}) {
		params.seed = params.seed ?? 1234;
		super(params as ParseableModel);
		this.problem_type = 'SET';
		this.seed = DEFAULT_LIBRARY_SEED;
		this.answer_prefix = `QUESTION_${this.problem_id || 0}`;
		this.permission_level = 10;
		this.show_hints = true;
		this.show_solutions = true;
		this.show_correct_answers_button = true;
		this._param_fields = {
			problem_path: {
				field_type: 'string'
			},
			library_id: {
				field_type: 'non_neg_int'
			},
			weight: {
				field_type: 'non_neg_int'
			}
		};
		this.problem_params = {} as SetProblemParams;
		if (params.problem_params) {
			this.setParams(params.problem_params as Dictionary<generic>);
		}
	}

	isValid() {
		const params = this.problem_params as SetProblemParams;
		return (this.problem_id && params.problem_path && this.problem_number) ? true : false;
	}

	rerandomize() {
		this.seed = random(10000, 99999);
	}

	path() {
		const params = this.problem_params as SetProblemParams;
		if (params.problem_path === undefined) throw 'This problem does not have a defined path';
		return params.problem_path;
	}
}

// problems to be rendered for Library Browser
export class LibraryProblem extends Problem {
	constructor(params: ParseableProblem = {}) {
		// Library response data doesn't overlap with our db structure
		// generate blank Problem and fill it in facade-style
		super({} as ParseableModel);
		this.problem_type = 'LIBRARY';
		// default seed value for viewing library problems
		this.seed = DEFAULT_LIBRARY_SEED;
		this.permission_level = 10;
		this.show_hints = true;
		this.show_solutions = true;
		this.show_correct_answers_button = true;

		this._param_fields = {
			id: {
				field_type: 'non_neg_int'
			},
			file_path: {
				field_type: 'string'
			}
		};
		this.problem_params = {} as LibraryParams;
		if (params) {
			this.setParams(params as Dictionary<generic>);
		}
		// they haven't been assigned, so no problem_id or problem_number
		// we still need unique problem prefixes, so use library_id as problem_number
		this.problem_number = (this.problem_params as LibraryParams).id;
		this.answer_prefix = `QUESTION_${this.problem_number || 0}`;

	}

	isValid() {
		const params = this.problem_params as LibraryParams;
		return (params.file_path && this.problem_number) ? true : false;
	}

	rerandomize() {
		logger.debug(`[LibraryProblem/rerandomize] changing seed (${this.seed || 0}) on problem ${this.path()}`);
		this.seed = random(10000, 99999);
		logger.debug(`[LibraryProblem/rerandomize] new seed is ${this.seed}.`);
	}

	path() {
		const params = this.problem_params as LibraryParams;
		if (params.file_path === undefined) throw 'This problem does not have a defined path';
		return params.file_path;
	}
}

export function parseProblem(problem: ParseableProblem, type: string) {
	switch (type) {
	case 'Library': return new LibraryProblem(problem);
	case 'Set': return new SetProblem(problem);
	}
}

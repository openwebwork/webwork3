
/* These are Problem interfaces */

import { RendererParams } from 'src/api-requests/renderer';
import { Dictionary, Model, generic, ParseableModel, ModelField, parseParams } from 'src/store/models/index';
import { random } from 'lodash';

export enum ProblemType {
	SET = 'SET',
	LIBRARY = 'LIBRARY',
	HW = 'HW',
	QUIZ = 'QUIZ',
	REVIEW = 'REVIEW',
}

export const DEFAULT_LIBRARY_SEED = 1234;

/* Problem class */

export interface ParseableProblem {
	problem_id?: string | number;
	set_id?: string | number;
	seed?: string | number;
	id?: string | number; // library_id from OPLv3
	problem_number?: string | number;
	problem_version?: string | number;
	problem_params?: ProblemParams;
	renderer_params?: RendererParams;
}

export interface SetProblemParams {
	file_path?: string;
	library_id?: string | number;
	weight?: number;
}

export interface ProblemParams extends Dictionary<generic> {
	library_id: number;
	file_path: string;
}

export class Problem extends Model(
	[], ['problem_id', 'set_id', 'seed', 'id', 'problem_number', 'problem_version'],
	[], ['problem_params', 'renderer_params'],
	{
		problem_id: { field_type: 'non_neg_int', default_value: 0 },
		set_id: { field_type: 'non_neg_int', default_value: 0 },
		id: { field_type: 'non_neg_int', default_value: 0 },
		problem_number: { field_type: 'non_neg_int', default_value: 0 },
		problem_version: { field_type: 'non_neg_int', default_value: 0 },
	}) {
	static REQUIRED_FIELDS = [];
	static OPTIONAL_FIELDS = ['problem_id', 'set_id', 'id'];

	problem_type = '';
	_param_fields: ModelField = {
		library_id: { field_type: 'non_neg_int' },
		file_path: { field_type: 'string' }
	};
	_request_fields: ModelField = {
		seed: { field_type: 'non_neg_int', default_value: 0 },
		permission_level: { field_type: 'non_neg_int', default_value: 0 },
		output_format: { field_type: 'string', default_value: 'ww3' },
		answer_prefix: { field_type: 'string', default_value: '' },
		show_hints: { field_type: 'boolean', default_value: false },
		show_solutions: { field_type: 'boolean', default_value: false },
		// TODO: drop the button booleans
		show_preview_button: { field_type: 'boolean', default_value: false },
		show_check_answers_button: { field_type: 'boolean', default_value: false },
		show_correct_answers_button: { field_type: 'boolean', default_value: false }
	}
	problem_params: ProblemParams = { library_id: 0, file_path: '' };
	renderer_params = {
		problemSeed: DEFAULT_LIBRARY_SEED,
		permission_level: 0,
		outputFormat: 'ww3',
		answerPrefix: '',
		showHints: false,
		showSolutions: false,
		showPreviewButton: false,
		showCheckAnswersButton: false,
		showCorrectAnswersButton: false
	}

	constructor(params: ParseableProblem = {}) {
		super(params as ParseableModel);
		this.setParams(params.problem_params);
	}

	setParams(params: Dictionary<generic> = {}) {
		this.problem_params = parseParams(params, this._param_fields) as ProblemParams;
	}

	isValid() {
		throw 'You must override the isValid() method';
	}

	// override this for problem-types which may be re-randomized
	rerandomize() {
		throw 'This problem may not be re-randomized.';
	}

	// override this in children
	clone(): Problem {
		throw 'You must override the clone method';
	}

	// facade for library/set/assigned problems
	path(): string {
		throw 'Subclass has not defined the source path';
	}

	// return the RendererRequest params for this Problem
	requestParams(): RendererParams {
		if (this.renderer_params.problemSeed === undefined) {
			throw 'Cannot generate requestParams for problem because there is no seed value.';
		}
		if (this.renderer_params.outputFormat === undefined) {
			throw 'Cannot generate requestParams for problem because there is no output format';
		}

		return {
			problemSeed: this.renderer_params.problemSeed,
			outputFormat: this.renderer_params.outputFormat,
			sourceFilePath: this.path(), // will this respect inheritance?
			problemNumber: this.problem_number ?? this.problem_params.library_id ?? 0,
			answerPrefix: this.renderer_params.answerPrefix,
			permissionLevel: this.renderer_params.permission_level,
			language: 'en',
			showHints: this.renderer_params.showHints,
			showSolutions: this.renderer_params.showSolutions,
			showPreviewButton: this.renderer_params.showPreviewButton,
			showCheckAnswersButton: this.renderer_params.showCheckAnswersButton,
			showCorrectAnswersButton: this.renderer_params.showCorrectAnswersButton,
		};
	}
}

// problems to be rendered for sets editor
export class SetProblem extends Problem {
	constructor(params: ParseableProblem = {}) {
		super(params as ParseableModel);
		this.problem_type = 'SET';
		this.renderer_params.answerPrefix = `QUESTION_${this.problem_id || 0}`;
		this.renderer_params.problemSeed = params.renderer_params?.problemSeed ?? 1234;
		this._param_fields = {
			file_path: {
				field_type: 'string'
			},
			library_id: {
				field_type: 'non_neg_int'
			},
			weight: {
				field_type: 'non_neg_int'
			}
		};
	}

	isValid() {
		const params = this.problem_params as SetProblemParams;
		return this.problem_id && params.file_path && this.problem_number;
	}

	rerandomize() {
		this.renderer_params.problemSeed = random(10000, 99999);
	}

	clone(): SetProblem {
		return new SetProblem(this.toObject() as ParseableProblem);
	}

	path() {
		const params = this.problem_params as SetProblemParams;
		return params.file_path ?? '';
	}
}

// problems to be rendered for Library Browser
export class LibraryProblem extends Problem {
	constructor(params: ParseableProblem = {}) {
		// Library response data doesn't overlap with our db structure
		// generate blank Problem and fill it in facade-style
		super(params);
		this.problem_type = 'LIBRARY';
		// default seed value for viewing library problems
		this.renderer_params.problemSeed = DEFAULT_LIBRARY_SEED;
		this.renderer_params.permission_level = 10;

		this._param_fields = {
			library_id: {
				field_type: 'non_neg_int'
			},
			file_path: {
				field_type: 'string'
			}
		};
		// they haven't been assigned, so no problem_id or problem_number
		// we still need unique problem prefixes, so use library_id as problem_number
		// this.problem_number = (this.problem_params as LibraryParams).id;
		this.renderer_params.answerPrefix = `QUESTION_${this.problem_number || 0}`;
	}

	isValid() {
		return this.problem_params.file_path && this.problem_number;
	}

	rerandomize() {
		this.renderer_params.problemSeed = random(10000, 99999);
	}

	clone(): LibraryProblem {
		return new LibraryProblem(this.toObject() as ParseableProblem);
	}

	path() {
		const params = this.problem_params as SetProblemParams;
		return params.file_path ?? '';
	}
}

export function parseProblem(problem: ParseableProblem, type: string) {
	switch (type) {
	case 'Library': return new LibraryProblem(problem);
	case 'Set': return new SetProblem(problem);
	}
}

/* Library interfaces */

import { parseNonNegInt } from './index';
import { Dictionary, generic, Model, ParseableModel } from './index';
import { SubmitButton } from 'src/typings/renderer';

export interface Discipline {
	id: number;
	name: string;
	official: boolean;
}

export interface LibrarySubject {
	id: number;
	name: string;
	official: boolean;
}

export interface RenderedProblem {
	problem_id: number;
	file_path: string;
	problem_html: string;
	answer_html: string;
	render_error: string;
	submit_buttons: Array<SubmitButton>;
	js: Array<string>;
	css: Array<string>;
}

export type ParseableLibraryParams = Partial<LibraryProblemParams>;

export interface LibraryProblemParams extends Dictionary<generic> {
	file_path: string;
	weight: number;
	library_problem_id: number;
}

export interface ParseableLibraryProblem {
	problem_id?: number|string;
	problem_number?: number|string;
	problem_version?: number|string;
	set_id?: number|string;
	problem_params?: Partial<LibraryProblemParams>;
}

export class LibraryProblem extends Model(
	[], ['problem_id', 'problem_number', 'problem_version', 'set_id'], [], ['problem_params'],
	{
		problem_id: { field_type: 'non_neg_int', default_value: 0 },
		problem_number: { field_type: 'non_neg_int', default_value: 0 },
		problem_version: { field_type: 'non_neg_int', default_value: 0 },
		set_id: { field_type: 'non_neg_int', default_value: 0 },
	}
) {
	problem_params: LibraryProblemParams = {
		file_path: '',
		weight: 1,
		library_problem_id: 0
	};

	constructor(params: ParseableLibraryProblem = {}) {
		super(params as ParseableModel);
		this.setParams(params.problem_params as ParseableLibraryParams);
	}

	setParams(params: ParseableLibraryParams = {}) {
		if (params.file_path) {
			this.problem_params.file_path = params.file_path;
		}
		if (params.library_problem_id){
			this.problem_params.library_problem_id = parseNonNegInt(`${params.library_problem_id}`);
		}
		if (params.weight) {
			this.problem_params.weight = parseFloat(`${params.weight}`);
		}
	}
}

/* Library interfaces */

import { Dictionary, generic, Model, ParseableModel } from './index';
import { clone } from 'lodash-es';

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
	problem_params?: LibraryProblemParams;
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
	constructor(params: ParseableLibraryProblem = {}) {
		super(params as ParseableModel);
		this.problem_params = clone(params.problem_params);
	}
}

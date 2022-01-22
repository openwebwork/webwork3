import { parseNonNegInt } from './parsers-new';
import { Model } from './model-new';

// This is associated with problems from the Library (OPLv3 or local)

export interface ParseableLibraryProblem {
	library_id?: string | number;
	file_path?: string;
}

export class LibProblem extends Model {
	private _library_id?: number;
	private _file_path?: string;

	constructor(params: ParseableLibraryProblem = {}) {
		super();
		this.set(params);
	}

	get all_field_names() {
		return ['library_id', 'file_path'];
	}

	set(params: ParseableLibraryProblem) {
		if (params.library_id) this.library_id = params.library_id;
		if (params.file_path) this.file_path = params.file_path;
	}

	get library_id() { return this._library_id; }
	set library_id(value: number | string | undefined) {
		if (value) this._library_id = parseNonNegInt(value);
	}

	get file_path() { return this._file_path; }
	set file_path(value: string | undefined) {
		if (value) this._file_path = value;
	}
}

import { AddRendering } from './renderer-new';

export const LibraryProblem = AddRendering(LibProblem);

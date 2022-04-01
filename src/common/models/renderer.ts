// This file contains a class used to provide rendering fields for typically
// problems.

// This also contains functionality for a mixin to pull in the functionality.

import { Model } from '.';
import { parseBoolean, parseNonNegInt } from './parsers';
export interface LibraryParams {
	library_id?: number;
	file_path?: string;
	problem_pool_id?: number;
}

export interface ParseableRenderParams {
	problemSeed?: number | string;
	permissionLevel?: number | string;
	outputFormat?: string;
	answerPrefix?: string;
	showHints?: number | string | boolean;
	showSolutions?: number | string | boolean;
	showPreviewButton?: number | string | boolean;
	showCheckAnswersButton?: number | string | boolean;
	showCorrectAnswersButton?: number | string | boolean;
	sourceFilePath?: string;
}

export class RenderParams extends Model {
	private _problemSeed = 1234;
	private _permissionLevel = 0;
	private _outputFormat = 'ww3';
	private _answerPrefix = '';
	private _sourceFilePath = '';
	private _showHints = false;
	private _showSolutions = false;
	private _showPreviewButton = false;
	private _showCheckAnswersButton = false;
	private _showCorrectAnswersButton = false;

	constructor(params: ParseableRenderParams = {}) {
		super();
		this.set(params);
	}

	get all_field_names(): string[] {
		return ['problemSeed', 'permissionLevel', 'outputFormat', 'answerPrefix',
			'sourceFilePath', 'showHints', 'showSolutions', 'showPreviewButton',
			'showCheckAnswersButton', 'showCorrectAnswersButton'];
	}
	get param_fields(): string[] { return [];}

	set(params: ParseableRenderParams) {
		if (params.problemSeed != undefined) this.problemSeed = params.problemSeed;
		if (params.permissionLevel != undefined) this.permissionLevel = params.permissionLevel;
		if (params.outputFormat != undefined) this.outputFormat = params.outputFormat;
		if (params.answerPrefix != undefined) this.answerPrefix = params.answerPrefix;
		if (params.sourceFilePath != undefined) this.sourceFilePath = params.sourceFilePath;
		if (params.showHints != undefined) this.showHints = params.showHints;
		if (params.showSolutions != undefined) this.showSolutions = params.showSolutions;
		if (params.showPreviewButton != undefined) this.showPreviewButton = params.showPreviewButton;
		if (params.showCheckAnswersButton != undefined) this.showCheckAnswersButton = params.showCheckAnswersButton;
		if (params.showCorrectAnswersButton != undefined) {
			this.showCorrectAnswersButton = params.showCorrectAnswersButton;
		}
	}

	public get problemSeed() : number { return this._problemSeed;}
	public set problemSeed(value: number | string) { this._problemSeed = parseNonNegInt(value);}

	public get permissionLevel() : number { return this._permissionLevel;}
	public set permissionLevel(value: number | string) { this._permissionLevel = parseNonNegInt(value);}

	public get outputFormat() : string { return this._outputFormat;}
	public set outputFormat(value: string) { this._outputFormat = value;}

	public get answerPrefix() : string { return this._answerPrefix;}
	public set answerPrefix(value: string) { this._answerPrefix = value;}

	public get sourceFilePath() : string { return this._sourceFilePath;}
	public set sourceFilePath(value: string) { this._sourceFilePath = value;}

	public get showHints() : boolean { return this._showHints;}
	public set showHints(value: number | string | boolean) { this._showHints = parseBoolean(value);}

	public get showSolutions() : boolean { return this._showSolutions;}
	public set showSolutions(value: number | string | boolean) { this._showSolutions = parseBoolean(value);}

	public get showPreviewButton() : boolean { return this._showPreviewButton;}
	public set showPreviewButton(value: number | string | boolean) { this._showPreviewButton = parseBoolean(value);}

	public get showCheckAnswersButton() : boolean { return this._showCheckAnswersButton;}
	public set showCheckAnswersButton(value: number | string | boolean) {
		this._showCheckAnswersButton = parseBoolean(value);
	}

	public get showCorrectAnswersButton() : boolean { return this._showCorrectAnswersButton;}
	public set showCorrectAnswersButton(value: number | string | boolean) {
		this._showCorrectAnswersButton = parseBoolean(value);
	}

}

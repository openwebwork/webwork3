// Tests basic functionality of a Problem and Render Parameters.

import { BooleanParseException, NonNegIntException } from 'src/common/models/parsers';
import { Problem } from 'src/common/models/problems';

describe('Testing basic problem render model functions', () => {
	const default_render_params = {
		problemSeed: 1234,
		permissionLevel: 0,
		outputFormat: 'ww3',
		answerPrefix: '',
		sourceFilePath: '',
		showHints: false,
		showSolutions: false,
		showPreviewButton: false,
		showCheckAnswersButton: false,
		showCorrectAnswersButton: false
	};

	test('Create a basic problem', () => {
		const prob = new Problem();
		expect(prob instanceof Problem).toBe(true);
		expect(prob.render_params.toObject()).toStrictEqual(default_render_params);

	});

	test('check setters/getters of basic problem', () => {
		const prob = new Problem();

		prob.render_params.problemSeed = '4321';
		expect(prob.render_params.problemSeed).toBe(4321);

		prob.render_params.problemSeed = 789;
		expect(prob.render_params.problemSeed).toBe(789);

		prob.render_params.permissionLevel = 10;
		expect(prob.render_params.permissionLevel).toBe(10);

		prob.render_params.permissionLevel = '5';
		expect(prob.render_params.permissionLevel).toBe(5);

		prob.render_params.outputFormat = 'xyz';
		expect(prob.render_params.outputFormat).toBe('xyz');

		prob.render_params.sourceFilePath = 'the_file_path';
		expect(prob.render_params.sourceFilePath).toBe('the_file_path');

		prob.render_params.showHints = true;
		expect(prob.render_params.showHints).toBe(true);

		prob.render_params.showHints = '0';
		expect(prob.render_params.showHints).toBe(false);

		prob.render_params.showHints = 'true';
		expect(prob.render_params.showHints).toBe(true);

		prob.render_params.showSolutions = true;
		expect(prob.render_params.showSolutions).toBe(true);

		prob.render_params.showSolutions = '0';
		expect(prob.render_params.showSolutions).toBe(false);

		prob.render_params.showSolutions = 'true';
		expect(prob.render_params.showSolutions).toBe(true);

		prob.render_params.showPreviewButton = true;
		expect(prob.render_params.showPreviewButton).toBe(true);

		prob.render_params.showPreviewButton = '0';
		expect(prob.render_params.showPreviewButton).toBe(false);

		prob.render_params.showPreviewButton = 'true';
		expect(prob.render_params.showPreviewButton).toBe(true);

		prob.render_params.showCheckAnswersButton = true;
		expect(prob.render_params.showCheckAnswersButton).toBe(true);

		prob.render_params.showCheckAnswersButton = '0';
		expect(prob.render_params.showCheckAnswersButton).toBe(false);

		prob.render_params.showCheckAnswersButton = 'true';
		expect(prob.render_params.showCheckAnswersButton).toBe(true);

		prob.render_params.showCorrectAnswersButton = true;
		expect(prob.render_params.showCorrectAnswersButton).toBe(true);

		prob.render_params.showCorrectAnswersButton = '0';
		expect(prob.render_params.showCorrectAnswersButton).toBe(false);

		prob.render_params.showCorrectAnswersButton = 'true';
		expect(prob.render_params.showCorrectAnswersButton).toBe(true);
	});

	test('check that set() works for basic problem', () => {
		const prob = new Problem();

		prob.setRenderParams({ problemSeed: '4321' });
		expect(prob.render_params.problemSeed).toBe(4321);

		prob.setRenderParams({ problemSeed: 789 });
		expect(prob.render_params.problemSeed).toBe(789);

		prob.setRenderParams({ permissionLevel: 10 });
		expect(prob.render_params.permissionLevel).toBe(10);

		prob.setRenderParams({ permissionLevel: '5' });
		expect(prob.render_params.permissionLevel).toBe(5);

		prob.setRenderParams({ outputFormat: 'xyz' });
		expect(prob.render_params.outputFormat).toBe('xyz');

		prob.setRenderParams({ sourceFilePath: 'the_file_path' });
		expect(prob.render_params.sourceFilePath).toBe('the_file_path');

		prob.setRenderParams({ showHints: true });
		expect(prob.render_params.showHints).toBe(true);

		prob.setRenderParams({ showHints: '0' });
		expect(prob.render_params.showHints).toBe(false);

		prob.setRenderParams({ showHints: 'true' });
		expect(prob.render_params.showHints).toBe(true);

		prob.setRenderParams({ showSolutions: true });
		expect(prob.render_params.showSolutions).toBe(true);

		prob.setRenderParams({ showSolutions: '0' });
		expect(prob.render_params.showSolutions).toBe(false);

		prob.setRenderParams({ showSolutions: 'true' });
		expect(prob.render_params.showSolutions).toBe(true);

		prob.setRenderParams({ showPreviewButton: true });
		expect(prob.render_params.showPreviewButton).toBe(true);

		prob.setRenderParams({ showPreviewButton: '0' });
		expect(prob.render_params.showPreviewButton).toBe(false);

		prob.setRenderParams({ showPreviewButton: 'true' });
		expect(prob.render_params.showPreviewButton).toBe(true);

		prob.setRenderParams({ showCheckAnswersButton: true });
		expect(prob.render_params.showCheckAnswersButton).toBe(true);

		prob.setRenderParams({ showCheckAnswersButton: '0' });
		expect(prob.render_params.showCheckAnswersButton).toBe(false);

		prob.setRenderParams({ showCheckAnswersButton: 'true' });
		expect(prob.render_params.showCheckAnswersButton).toBe(true);

		prob.setRenderParams({ showCorrectAnswersButton: true });
		expect(prob.render_params.showCorrectAnswersButton).toBe(true);

		prob.setRenderParams({ showCorrectAnswersButton: '0' });
		expect(prob.render_params.showCorrectAnswersButton).toBe(false);

		prob.setRenderParams({ showCorrectAnswersButton: 'true' });
		expect(prob.render_params.showCorrectAnswersButton).toBe(true);
	});

	test('Check that setting invalid parameters throw an error.', () => {
		const prob = new Problem();
		expect(() => { prob.render_params.problemSeed = -1;}).toThrow(NonNegIntException);
		expect(() => { prob.render_params.problemSeed = '-1';}).toThrow(NonNegIntException);
		expect(() => { prob.render_params.problemSeed = 'one';}).toThrow(NonNegIntException);

		expect(() => { prob.render_params.permissionLevel = -1;}).toThrow(NonNegIntException);
		expect(() => { prob.render_params.permissionLevel = '-1';}).toThrow(NonNegIntException);
		expect(() => { prob.render_params.permissionLevel = 'one';}).toThrow(NonNegIntException);

		expect(() => { prob.render_params.showHints = -1;}).toThrow(BooleanParseException);
		expect(() => { prob.render_params.showHints = 2;}).toThrow(BooleanParseException);
		expect(() => { prob.render_params.showHints = 'TrUe';}).toThrow(BooleanParseException);

		expect(() => { prob.render_params.showSolutions = -1;}).toThrow(BooleanParseException);
		expect(() => { prob.render_params.showSolutions = 2;}).toThrow(BooleanParseException);
		expect(() => { prob.render_params.showSolutions = 'TrUe';}).toThrow(BooleanParseException);

	});

	test('Check that setting invalid parameters via the setRenderParams() method throws an error', () => {
		const prob = new Problem();
		expect(() => { prob.setRenderParams({ permissionLevel: -1 });}).toThrow(NonNegIntException);
		expect(() => { prob.setRenderParams({ permissionLevel: -1 });}).toThrow(NonNegIntException);
		expect(() => { prob.setRenderParams({ permissionLevel: -1 });}).toThrow(NonNegIntException);

		expect(() => { prob.setRenderParams({ showCheckAnswersButton: 2 });}).toThrow(BooleanParseException);
		expect(() => { prob.setRenderParams({ showCheckAnswersButton: '-1' });}).toThrow(BooleanParseException);
		expect(() => { prob.setRenderParams({ showCheckAnswersButton: 'faLse' });}).toThrow(BooleanParseException);

	});
});

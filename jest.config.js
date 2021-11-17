/* eslint-env node */

const { pathsToModuleNameMapper } = require('ts-jest/utils');
const requireJSON5 = require('require-json5');
const { compilerOptions } = requireJSON5('./node_modules/@quasar/app/tsconfig-preset.json');

module.exports = {
	preset: 'ts-jest',
	testEnvironment: 'node',
	globals: {
		'ts-jest': {
			'tsconfig': 'tsconfig.json',
			'diagnostics': true
		}
	},
	moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths, { prefix: '<rootDir>/' }),
	testRegex: '(/tests/.*|(\\.|/)(test|spec))\\.(jsx?|tsx?)$',
};

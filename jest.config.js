/* eslint-disable no-undef */

/** @type {import('ts-jest/dist/types').InitialOptionsTsJest} */
const { pathsToModuleNameMapper } = require('ts-jest/utils')
// In the following statement, replace `./tsconfig` with the path to your `tsconfig` file
// which contains the path mapping (ie the `compilerOptions.paths` option):

const { compilerOptions } = require('./tsconfig')



module.exports = {
	preset: 'ts-jest',
	testEnvironment: 'node',
	globals: {
		"ts-jest": {
			"tsconfig": "tsconfig.json",
			"diagnostics": true
		}
	},
	// A map from regular expressions to module names that allow to stub out resources with a single module
	// moduleNameMapper: {
	//   '^@/(.*)$': '<rootDir>/src/$1',
	// },
	moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths , { prefix: '<rootDir>/' } ),
	testRegex: "(/tests/.*|(\\.|/)(test|spec))\\.(jsx?|tsx?)$",
};

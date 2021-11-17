/* eslint-env node */

module.exports = {
	preset: 'ts-jest',
	testEnvironment: 'node',
	globals: {
		'ts-jest': {
			'tsconfig': 'tsconfig.json',
			'diagnostics': true
		}
	},
	moduleNameMapper: {
		'^src/(.*)$': '<rootDir>/src/$1',
		'^app/(.*)$': '<rootDir>/$1',
		'^components/(.*)$': '<rootDir>/src/components/$1',
		'^layouts/(.*)$': '<rootDir>/src/layouts/$1',
		'^pages/(.*)$': '<rootDir>/src/pages/$1',
		'^assets/(.*)$': '<rootDir>/src/assets/$1',
		'^boot/(.*)$': '<rootDir>/src/boot/$1'
	},
	testRegex: '(/tests/.*|(\\.|/)(test|spec))\\.(jsx?|tsx?)$',
};

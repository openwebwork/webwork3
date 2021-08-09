const { resolve } = require('path');
module.exports = {
	root: true,

	parserOptions: {
		extraFileExtensions: ['.vue'],
		parser: '@typescript-eslint/parser',
		project: resolve(__dirname, './tsconfig.json'),
		tsconfigRootDir: __dirname,
		ecmaVersion: 2018, // Allows for the parsing of modern ECMAScript features
		sourceType: 'module' // Allows for the use of imports
	},

	env: {
		browser: true
	},

	// Rules order is important, please avoid shuffling them
	extends: [
		'plugin:@typescript-eslint/recommended',
		// consider disabling this class of rules if linting takes too long
		'plugin:@typescript-eslint/recommended-requiring-type-checking',
		'plugin:vue/vue3-essential',
		'prettier'
	],

	plugins: [
		'@typescript-eslint',
		'vue'
	],

	globals: {
		__statics: 'readonly',
		process: 'readonly'
	},

	rules: {
		'prefer-promise-reject-errors': 'off',

		// TypeScript
		quotes: ['warn', 'single', { avoidEscape: true }],
		'@typescript-eslint/explicit-function-return-type': 'off',
		'@typescript-eslint/explicit-module-boundary-types': 'off',

		// General syntax
		'no-tabs': ['error', { allowIndentationTabs: true }],
		'indent': ['error', 'tab'],
		'max-len': ['error', { ignoreUrls: true, code: 120 }],
		'no-multiple-empty-lines': ['error', { max: 1, maxEOF: 0, maxBOF: 1 }],
		'space-in-parens': ['error', 'never'],
		'object-curly-spacing': ['error', 'always'],
		'comma-spacing': ['error', { before: false, after: true }],
		'comma-dangle': ['error', 'never'],
		'semi': ['error', 'always'],
		'generator-star-spacing': 'off',
		'arrow-parens': 'off',
		'one-var': 'off',
		'no-void': 'off',
		'multiline-ternary': 'off',

		// allow console and debugger during development only
		'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off',
		'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off'
	}
}

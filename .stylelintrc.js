module.exports = {
	extends: ['stylelint-config-standard', 'stylelint-config-prettier', 'stylelint-config-recommended-scss'],
	plugins: ['stylelint-scss'],
	ignoreFiles: ['node_modules/**', 'dist/**'],
	rules: {
		'at-rule-no-unknown': null,
		'scss/at-rule-no-unknown': true,
		'indentation': 'tab',
		'max-empty-lines': 1,
		'rule-empty-line-before': ['always', {
			except: ['first-nested']
		}],
		'no-descending-specificity': null,
		'no-invalid-position-at-import-rule': null,
		'selector-pseudo-class-no-unknown': [true, {
			ignorePseudoClasses: ['deep', 'v-deep']
		}],

	}
}

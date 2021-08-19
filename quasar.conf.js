/* eslint-env node */
/* eslint-disable @typescript-eslint/no-var-requires */
const { configure } = require('quasar/wrappers');
const StyleLintPlugin = require('stylelint-webpack-plugin');

module.exports = configure(function (ctx) {
	return {
		supportTS: {
			tsCheckerConfig: {
				eslint: {
					enabled: true,
					files: './src/**/*.{ts,tsx,js,jsx,vue}'
				}
			}
		},

		boot: [
			'axios',
			'i18n'
		],

		css: [
			'app.scss'
		],

		extras: [
			'roboto-font',
			'material-icons'
		],

		framework: {
			plugins: [
				'Notify'
			],
			config: {
				notify: { /* look at QuasarConfOptions from the API card */ }
			}
		},

		build: {
			vueRouterMode: 'history',
			publicPath: '/webwork3',

			chainWebpack(chain) {
				chain.plugin('stylelint-webpack').use(new StyleLintPlugin({
					emitError: ctx.prod ? true : false,
					extensions: ['vue', 'html', 'css', 'scss', 'sass'],
					files: ['**/*.{vue,html,css,scss,sass}'],
					exclude: ['node_modules', 'dist']
				}));
			}
		},

		devServer: {
			https: false,
			port: 8080,
			open: true, // opens browser window automatically,
			proxy: { '/webwork3/api': 'http://localhost:3000' }
		}
	};
});

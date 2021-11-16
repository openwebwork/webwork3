/* eslint-env node */

const { configure } = require('quasar/wrappers');
const StyleLintPlugin = require('stylelint-webpack-plugin');
const path = require('path');
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin');

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
			'i18n',
			'logger'
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

				chain.plugin('nodePolyfills').use(NodePolyfillPlugin);

				if (ctx.prod) {
					chain.plugin('copy-webpack')
						.tap(args => {
							args[0].patterns.push({
								from: path.resolve(__dirname, './node_modules/mathjax/es5'),
								to: path.resolve(__dirname, './dist/spa/mathjax'),
								toType: 'dir'
							});
							return args;
						});
				}
			},

			extendWebpack(cfg) {
				if (cfg.optimization && cfg.optimization.minimizer instanceof Array) {
					cfg.optimization.minimizer.forEach((plugin) => {
						if (plugin.constructor.name == 'TerserPlugin')
							plugin.options.exclude = /.*mathjax.*/;
					});
				}

				cfg.module.rules.push ({
					test: /\.m?js/,
					resolve: {
						fullySpecified: false,
						fallback: {
							crypto: false,
							fs: false
						}
					}
				});
			}
		},

		devServer: {
			https: false,
			port: 8080,
			open: true, // opens browser window automatically,
			proxy: {
				'/webwork3/api': 'http://localhost:3000',
				'/renderer': 'http://localhost:3001',
				'/opl': {
					target: 'http://localhost:3030',
					changeOrigin: true,
					pathRewrite: {
						'^/opl': ''
					}
				}
			},
			static: path.join(__dirname, 'node_modules/mathjax/es5'),
			historyApiFallback: {
				rewrites: [{
					from: /^\/webwork3\/mathjax\/.*$/,
					to: (context) => context.parsedUrl.pathname.replace(/^\/webwork3\/mathjax/, '')
				}]
			}
		}
	};
});

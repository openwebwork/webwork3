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
			'pinia',
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
				'Notify',
				'Dialog'
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

				if (cfg.optimization && cfg.optimization.splitChunks) {
					cfg.optimization.splitChunks.cacheGroups.defaultVendors = {
						test: /[\\/]node_modules[\\/]/,
						name(module) { return module.identifier().split('/').reduceRight((item) => item); },
						chunks: 'all',
						reuseExistingChunk: true
					};
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

				// For i18n resources (json/json5/yaml)
				cfg.module.rules.push({
					test: /\.(json5?|ya?ml)$/,
					type: 'javascript/auto',
					include: [ path.resolve(__dirname, './src/locales') ],
					loader: '@intlify/vue-i18n-loader'
				});
			}
		},

		devServer: {
			https: false,
			port: 8080,
			open: false, // opens browser window automatically,
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

import { boot } from 'quasar/wrappers';
import winston from 'winston';
import 'setimmediate';

const logger = winston.createLogger({
	level: 'debug',
	format: winston.format.simple(),
	defaultMeta: {
		get location() { return window.location.href; },
		userAgent: window.navigator.userAgent,
		service: 'webwork3'
	},
	transports: [
		new winston.transports.Http({
			level: 'error',
			host: 'localhost',
			port: 8080,
			path: `${process.env.VUE_ROUTER_BASE ?? ''}api/client-logs`,
			handleExceptions: true,
		})
	]
});

// If we're not in production then log to the console
if (process.env.NODE_ENV !== 'production') {
	logger.add(new winston.transports.Console({
		stderrLevels: ['error'],
		consoleWarnLevels: ['warn', 'debug'],
		format: winston.format.printf((info) => {return `[${info.level}] ${info.message}`;}),
		handleExceptions: true
	}));
}

export default boot(({ app }) => {
	// For use inside Vue files (Options API) through this.$logger
	app.config.globalProperties.$logger = logger;
});

export { logger };

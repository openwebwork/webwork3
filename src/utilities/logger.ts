/* eslint-disable no-tabs */
// import winston = require('winston');
import winston from 'winston';
import 'setimmediate';

const logger = winston.createLogger({
	level: 'info',
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
			path: '/webwork3/api/utility/client-logs',
			handleExceptions: true
		})
	]
});

//
// If we're not in production then log to the console
//
if (process.env.NODE_ENV !== 'production') {
	logger.add(new winston.transports.Console({
		format: winston.format.combine(
			winston.format.colorize({ all: true }),
			winston.format.simple()
		),
		handleExceptions: true
	}));
}

export default logger;
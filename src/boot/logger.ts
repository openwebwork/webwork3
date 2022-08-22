import { boot } from 'quasar/wrappers';
// import winston from 'winston';
import type { LogLevelNumbers } from 'loglevel';
import * as logger from 'loglevel';
import 'setimmediate';
import { api } from './axios';

logger.setLevel(process.env.NODE_ENV == 'production' ? 'error' : 'debug');

// This is needed as the methodFactory property of logger is readonly.
interface FactoryOverride {
	methodFactory: (methodName: string, logLevel: LogLevelNumbers, loggerName: string) => void;
}

// This mimics a plugin for the loglevel.  See https://github.com/pimterry/loglevel#writing-plugins
// for a similar example. This will send any errors to the backend to be logged.

const originalFactory = logger.methodFactory;
(logger as FactoryOverride).methodFactory = (methodName: string, logLevel: LogLevelNumbers, loggerName: string) => {
	const rawMethod = originalFactory(methodName, logLevel, loggerName);

	return function (message: string) {
		// If an error being logged, send the error to the backend.
		if (methodName === 'error') void api.post('/client-logs', { level: methodName, message });

		rawMethod(message);
	};
};
logger.setLevel(logger.getLevel()); // Be sure to call setLevel method in order to apply plugin

export default boot(({ app }) => {
	// For use inside Vue files (Options API) through this.$logger
	app.config.globalProperties.$logger = logger;
});

export { logger };

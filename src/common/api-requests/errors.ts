// General Error coming from the API service

import { logger } from 'boot/logger';
import { Model } from '../models';

export interface ResponseError {
	exception: string;
	message: string;
}

export const invalidError = (model: Model, msg: string) => {
	logger.error(msg);
	logger.error(JSON.stringify(model.toObject()));
	return Promise.reject(new Error(msg));
};

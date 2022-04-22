import type { User } from 'src/common/models/users';
import { parseBoolean } from './parsers';

export interface SessionInfo {
	user: User;
	logged_in: boolean;
	message: string;
}

export interface ParseableSessionInfo {
	user: User;
	logged_in: boolean | string | number;
	message: string;
}

export function parseSessionInfo(info: ParseableSessionInfo): SessionInfo {
	return {
		user: info.user,
		logged_in: parseBoolean(info.logged_in),
		message: info.message
	};
}

export interface UserPassword {
	username: string;
	password: string;
}

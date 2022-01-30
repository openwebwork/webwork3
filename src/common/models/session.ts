import { ParseableUser } from 'src/common/models/users';

export interface SessionInfo {
	user: ParseableUser;
	logged_in: boolean;
	message: string;
}

export interface UserPassword {
	username: string;
	password: string;
}

import { User } from 'src/common/models/users';

export interface SessionInfo {
	user: User;
	logged_in: boolean;
	message: string;
}

export interface UserPassword {
	username: string;
	password: string;
}

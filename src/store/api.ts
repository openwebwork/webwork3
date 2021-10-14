import { api } from 'boot/axios';
import type { SessionInfo, UserPassword } from './models';

export async function checkPassword(username: UserPassword): Promise<SessionInfo> {
	const response = await api.post('login', username);
	return response.data as SessionInfo;
}

export async function endSession() {
	await api.post('logout');
}

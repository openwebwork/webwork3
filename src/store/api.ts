import { api } from 'src/boot/axios';
import type { SessionInfo, UserPassword } from 'src/store/models/session';

export async function checkPassword(username: UserPassword): Promise<SessionInfo> {
	const response = await api.post('login', username);
	console.log(response);
	return response.data as SessionInfo;
}

export async function endSession() {
	await api.post('logout');
}

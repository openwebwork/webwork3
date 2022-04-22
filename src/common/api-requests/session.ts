import { api } from 'boot/axios';
import { parseSessionInfo, SessionInfo, ParseableSessionInfo, UserPassword } from 'src/common/models/session';

export async function checkPassword(username: UserPassword): Promise<SessionInfo> {
	const response = await api.post('login', username);
	return parseSessionInfo(response.data as ParseableSessionInfo);
}

export async function endSession() {
	await api.post('logout');
}

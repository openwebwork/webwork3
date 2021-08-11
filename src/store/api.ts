import axios from 'axios';
import type { SessionInfo, UserPassword } from './models';

export async function checkPassword(username: UserPassword): Promise<SessionInfo> {
	const response = await axios.post((process.env.VUE_ROUTER_BASE ?? '') + 'api/login', username);
	return response.data as SessionInfo;
}

import axios from 'axios';
import type { SessionInfo, UserPassword } from './models';

export async function checkPassword(login: UserPassword): Promise<SessionInfo> {
	const response = await axios.post((process.env.VUE_ROUTER_BASE ?? '') + 'api/login', login);
	return response.data as SessionInfo;
}

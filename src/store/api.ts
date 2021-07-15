import axios from 'axios';
// import { Session } from 'inspector';

import type { SessionInfo, UserPassword } from './models';

export async function checkPassword(login: UserPassword): Promise<SessionInfo> {
	const response = await axios.post('/webwork3/api/login', login);
	return response.data as SessionInfo;
}
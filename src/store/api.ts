import axios from "axios";

import type { LoginInfo, UserPassword, Course } from '@/store/models';

export async function checkPassword(login: UserPassword): Promise<LoginInfo> {
	const response = await axios.post('/webwork3/api/login', login);
	return response.data as LoginInfo;
}

export async function fetchUserCourses(user_id: number): Promise<Array<Course>> {
	const response = await axios.get(`/webwork3/api/users/${user_id}/courses`);
	return response.data as Array<Course>;
}

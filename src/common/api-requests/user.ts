import { api } from 'boot/axios';

import { ParseableCourseUser, ParseableUser } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/interfaces';

export async function checkIfUserExists(course_id: number, username: string) {
	const response = await api.get(`courses/${course_id}/users/${username}/exists`);
	if (response.status === 250) {
		throw response.data as ResponseError;
	}
	return response.data as ParseableCourseUser;
}
/**
 * queries the database to determine the user.
 * @param {string} username -- the username of the user.
 */
export async function getUser(username: string): Promise<ParseableUser> {
	const response = await api.get(`users/${username}`);
	if (response.status === 200) {
		return response.data as ParseableUser;
	} else {
		throw response.data as ResponseError;
	}
}

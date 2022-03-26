import { api } from 'boot/axios';

import { ParseableCourseUser } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/interfaces';

export async function checkIfUserExists(course_id: number, username: string) {
	const response = await api.get(`courses/${course_id}/users/${username}/exists`);
	if (response.status === 250) {
		throw response.data as ResponseError;
	}
	return response.data as ParseableCourseUser;
}

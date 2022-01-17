import { api } from 'boot/axios';

import { MergedUser } from 'src/store/models/users';
import { ResponseError } from 'src/store/models';

export async function checkIfUserExists(course_id: number, username: string) {
	const url = `courses/${course_id}/users/${username}/exists`;
	const response = await api.get(url);
	if (response.status === 250) {
		throw response.data as ResponseError;
	}
	return response.data as MergedUser;
}

import { api } from 'boot/axios';

import { ParseableUser, User } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/interfaces';

/**
 * queries the database to determine if the user exists.
 * @param {string} username -- the username of the user.
 * @return {User} the user if they exist.
 * @throws {ResponseError} if the user doesen't exist, this is thrown.
 */
export async function getUser(username: string): Promise<User> {
	const response = await api.get(`users/${username}`);
	if (response.status === 200) {
		return new User(response.data as ParseableUser);
	} else {
		throw response.data as ResponseError;
	}
}

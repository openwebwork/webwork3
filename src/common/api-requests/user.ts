import { api } from 'boot/axios';

import { ParseableUser, User } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/errors';

/**
 * Gets the global user in the database given by username. This returns a user or throws a
 * ResponseError if the user is not found.
 */
export async function getUser(username: string): Promise<User> {
	const response = await api.get(`users/${username}`);
	if (response.status === 200) {
		return new User(response.data as ParseableUser);
	} else {
		throw response.data as ResponseError;
	}
}

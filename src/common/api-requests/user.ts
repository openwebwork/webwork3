import { api } from 'boot/axios';

import { ParseableCourseUser, ParseableUser, User } from 'src/common/models/users';
import { ResponseError } from 'src/common/api-requests/errors';

/**
 * Checks if a global user exists. Both the course_id and username need to be passed in
 * in order to check permissions.
 *
 * @returns either an existing user or an empty object.
 */

export async function checkIfUserExists(course_id: number, username: string): Promise<ParseableCourseUser> {
	try {
		const response = await api.get(`courses/${course_id}/users/${username}/exists`);
		return response.data as ParseableCourseUser;
	} catch (err) {
		console.log(err);
		return {};
	}
}

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

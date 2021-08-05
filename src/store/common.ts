import { User } from './models';

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: false,
		last_name: '',
		login: '',
		student_id: '',
		user_id: undefined
	};
}
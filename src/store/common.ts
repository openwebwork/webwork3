import { User } from './models';

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: 0,
		last_name: '',
		login: '',
		student_id: '',
		user_id: 0
	};
}
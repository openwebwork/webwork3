export interface SessionState {
	logged_in: boolean;
	user: string;
	course_name: string;
}

function state(): SessionState {
	return {
		logged_in: false,
		user: '',
		course_name: ''
	};
}

export default state;

// This has common functionality needed for other utilities

export function parseBoolean(_value: string | number) {
	return _value === undefined ?
		undefined :
		parseInt(`${_value}`)===1 ? true: false ;
}

export const mailRE = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,9})/;
export const usernameRE = /^[a-zA-Z]([a-zA-Z._0-9])+$/;
export const user_roles = ['admin', 'instructor', 'student'];

// This has common functionality needed for other utilities

export function parseBoolean(_value: boolean | string | number) {
	if (typeof _value === 'boolean') return _value;
	if (typeof _value === 'string' && !(/[01]/.exec(_value))) {
		return _value === 'true' || _value === 'false' ?
			_value === 'true' :
			undefined;
	} else {
		return _value === undefined ?
			undefined :
			parseInt(`${_value}`) === 1;
	}
}

export const mailRE = /(\w+@[a-zA-Z_]+?\.[a-zA-Z]{2,9})/;
export const usernameRE = /^[a-zA-Z]([a-zA-Z._0-9])+$/;
export const user_roles = ['admin', 'instructor', 'TA', 'student'];

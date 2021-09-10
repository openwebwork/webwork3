// This has common functionality needed for other utilities

export function parseBoolean(_value: string | number) {
	return _value === undefined ?
		undefined :
		parseInt(`${_value}`)===1 ? true: false ;
}

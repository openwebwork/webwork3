export const pick = <T>(object: { [key: string]: T }, keys: Array<string>): { [key: string]: T } => {
	return keys.reduce((obj: { [key: string]: T }, key: string) => {
		if (object && Object.prototype.hasOwnProperty.call(object, key)) {
			obj[key] = object[key];
		}
		return obj;
	}, {});
};

export const mapValues = <T>(object: { [key: string]: T }, mapper: (key: T) => T): { [key: string]: T } => {
	return Object.entries(object).reduce((ret: { [key: string]: T }, [key, obj]) => {
		ret[key] = mapper(obj);
		return ret;
	}, {});
};

export const invert = (object: { [key: string]: string }) => {
	return Object.keys(object).reduce((acc, [key, value]) => ({ ...acc, [value]: key }), {});
};

export const pickBy = <T>(object: { [key: string]: T }, check: (value: T) => boolean) => {
	const obj: { [key: string]: T } = {};
	for (const [key, value] of Object.entries(object)) {
		if (check(value)) {
			obj[key] = object[key];
		}
	}
	return obj;
};

export const random = (max: number, min: number) => {
	min = Math.ceil(min);
	max = Math.floor(max);
	return Math.floor(Math.random() * (max - min) + min);
};

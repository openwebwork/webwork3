// Utility functions for testing

import { Dictionary, generic, Model } from 'src/common/models';

/**
 * Removes all fields ending in _id.  This is useful for comparing data from
 * the database where the internal _id are not important. This returns an array
 * of objects without the _id fields.
 */

export const cleanIDs = (m: Model | Model[]): Dictionary<generic> | Dictionary<generic>[] => {
	if (Array.isArray(m)) {
		return m.map(o => cleanIDs(o)) as Dictionary<generic>[];
	} else {
		const obj = m.toObject();
		return Object.keys(obj)
			.filter(k => k == 'student_id' || !/_id$/.test(k))
			.reduce((res: Dictionary<generic>, key: string) =>
				Object.assign(res, { [key]: obj[key] }), {});
	}
};

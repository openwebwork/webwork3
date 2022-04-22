// utils.ts

import { Dictionary, generic, Model } from 'src/common/models';
import { parseBoolean, parseNonNegInt } from 'src/common/models/parsers';
import papa from 'papaparse';
import fs from 'fs';

// Utility functions for testing
interface CSVConfig {
	params?: string[];
	boolean_fields?: string[];
	non_neg_fields?: string[];
	time_zone_shift?: number;
}

// type Output = Dictionary<string | number | boolean | Dictionary<string | number>>

/**
 * convert takes data in the form of an array of objects of strings or numbers
 * and converts to the proper form.  These typically come from a CSV file where
 * The dates and params are located in separate columns in the CSV file and are converted
 * to a nested object.  In addition, booleans and integers are parsed.
 *
 * @param data
 */

function convert(data: Dictionary<string>[], config: CSVConfig): Dictionary<generic | Dictionary<generic>>[] {
	const keys = Object.keys(data[0]);
	const param_fields = config.params ?? [];

	// Store the param fields and the matching regular expressions
	const p_fields: Dictionary<string[]> = {};
	param_fields.forEach(key => {
		const regexp = RegExp('^' + key.toUpperCase() + ':([\\w_]+)');
		p_fields[key] = keys.filter(k => regexp.test(k));
	});

	const all_param_fields = Object.entries(p_fields)
		.reduce((prev, [, value]) => prev = [...prev, ...value], [] as string[]);
	const known_fields = [...all_param_fields, ...(config.boolean_fields ?? []),
		...(config.non_neg_fields ?? [])];
	const other_fields = keys.filter(k => known_fields.indexOf(k) < 0);

	return data.map(row => {
		const d: Dictionary<generic | Dictionary<generic>> = {};
		// All non-param, non-boolean and non-integer fields don't need to be parsed.
		other_fields.forEach(key => { d[key] = row[key]; });
		// Parse boolean fields
		(config.boolean_fields ?? []).forEach(key => {
			if (row[key] != undefined) d[key] = parseBoolean(row[key]);
		});
		// Parse int fields
		(config.non_neg_fields ?? []).forEach(key => {
			if (row[key] != undefined) d[key] = parseNonNegInt(row[key]);
		});
		// Parse parameter fields
		Object.entries(p_fields).forEach(([key, ]) => {
			d[key] = p_fields[key].reduce((prev: Dictionary<string | number>, val) => {
				const field = val.split(':')[1];
				// Parse any date field as date.
				if (row[val]) {
					prev[field] = /DATES:/.test(val) ?
						// and shift due to timezone. THIS NEEDS TO BE FIXED. I don't know
						// why it is needed.
						Date.parse(row[val]) / 1000 - (config.time_zone_shift ?? 0) :
						row[val];
				}
				return prev;
			}, {});
		});
		return d;
	});
};

/**
 * load and parse a CSV file for testing.
 * @param filename
 * @param params_name
 * @param dates_name
 */

export async function loadCSV(filepath: string, config: CSVConfig):
	Promise< Dictionary<generic | Dictionary<generic>>[]> {
	const file = fs.createReadStream(filepath);
	return new Promise((resolve, reject) => {
		papa.parse(file, {
			header: true,
			complete (results) {
				return resolve(convert(results.data as Dictionary<string>[], config));
			},
			error (err) {
				return reject(err);
			}
		});
	});
}

/**
 * cleanIDs removes all fields ending in _id.  This is useful for comparing data from
 * the database where the internal _id are not important.
 *
 * @param {Model|Model[]} m - a model or array of models.
 * @returns a JS object or array of objects.
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

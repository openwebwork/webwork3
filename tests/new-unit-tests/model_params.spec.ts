// This tests the general features of instances of a ModelParam

import { ModelParams, RequiredFieldsException } from 'src/common/models';
import { BooleanParseException, NumberParseException, StringParseException } from 'src/common/models/parsers';

class SampleParams extends ModelParams(['bool1', 'bool2'], ['num1', 'num2'], ['str1'],
	{
		num1: { field_type: 'non_neg_int', default_value: 0 },
		num2: { field_type: 'number', default_value: 1.0 },
		bool1: { field_type: 'boolean', required: true }
	}) {}

test('Create an instance of a ModelParams', () => {

	const p = {
		bool1: true,
		bool2: false,
		num1: 1,
		num2: 0.5,
		str1: 'hello'
	};

	const params = new SampleParams(p);

	expect(params instanceof SampleParams).toBe(true);
	expect(params.toObject()).toStrictEqual(p);

});

test('Make sure default values are set correctly.', () => {
	const p1 = {
		bool1: true
	};
	const p2 = {
		bool1: true,
		num1: 0,
		num2: 1.0
	};
	const params = new SampleParams(p1);
	expect(params.toObject()).toStrictEqual(p2);
});

test('Ensure all passed in fields/value are parsed correctly', ()  => {
	expect(() => {
		new SampleParams({});
	}).toThrow(RequiredFieldsException);

	expect(() => {
		new SampleParams({
			num1: 1,
			num2: 0.5
		});
	}).toThrow(RequiredFieldsException);
});

test('Ensure that exceptions are thrown', () => {
	expect(() => {
		new SampleParams({
			bool1: 2,
			bool2: false
		});
	}).toThrow(BooleanParseException);

	expect(() => {
		new SampleParams({
			num1: '2',
			num2: 'false',
			bool1: true
		});
	}).toThrow(NumberParseException);

	expect(() => {
		new SampleParams({
			bool1: true,
			str1: 2.3
		});
	}).toThrow(StringParseException);

});

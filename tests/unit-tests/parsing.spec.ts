// This tests the parsing of various formats

import { parseNonNegInt, parseBoolean, parseEmail, parseUsername, EmailParseException,
	NonNegIntException, BooleanParseException, UsernameParseException,
	parseNonNegDecimal, NonNegDecimalException } from 'src/common/models/parsers';

describe('Testing parsing functions', () => {
	test('parsing nonnegative integers', () => {
		expect(parseNonNegInt(1)).toBe(1);
		expect(parseNonNegInt('1')).toBe(1);
		expect(parseNonNegInt(0)).toBe(0);
		expect(parseNonNegInt('0')).toBe(0);
		expect(() => {parseNonNegInt(-1);}).toThrow(NonNegIntException);
		expect(() => {parseNonNegInt('-1');}).toThrow(NonNegIntException);
	});

	test('parsing nonnegative decimals', () => {
		expect(parseNonNegDecimal(1.5)).toBe(1.5);
		expect(parseNonNegDecimal(0.5)).toBe(0.5);
		expect(parseNonNegDecimal(.5)).toBe(.5);
		expect(parseNonNegDecimal(2)).toBe(2);
		expect(parseNonNegDecimal('1.5')).toBe(1.5);
		expect(parseNonNegDecimal('0.5')).toBe(0.5);
		expect(parseNonNegDecimal('.5')).toBe(.5);
		expect(parseNonNegDecimal('2')).toBe(2);

		expect(() => {parseNonNegDecimal(-1);}).toThrow(NonNegDecimalException);
		expect(() => {parseNonNegDecimal(-0.5);}).toThrow(NonNegDecimalException);
		expect(() => {parseNonNegDecimal(-.5);}).toThrow(NonNegDecimalException);
	});

	test('parsing booleans', () => {
		expect(parseBoolean(true)).toBe(true);
		expect(parseBoolean(false)).toBe(false);
		expect(parseBoolean('true')).toBe(true);
		expect(parseBoolean('false')).toBe(false);
		expect(parseBoolean(1)).toBe(true);
		expect(parseBoolean(0)).toBe(false);
		expect(parseBoolean('1')).toBe(true);
		expect(parseBoolean('0')).toBe(false);
		expect(() => {parseBoolean('T');}).toThrow(BooleanParseException);
		expect(() => {parseBoolean('F');}).toThrow(BooleanParseException);
		expect(() => {parseBoolean('-1');}).toThrow(BooleanParseException);
		expect(() => {parseBoolean(-1);}).toThrow(BooleanParseException);
	});

	test('parsing emails', () => {
		expect(parseEmail('user@site.com')).toBe('user@site.com');
		expect(parseEmail('first.last@site.com')).toBe('first.last@site.com');
		expect(parseEmail('user1234@site.com')).toBe('user1234@site.com');
		expect(parseEmail('first.last@sub.site.com')).toBe('first.last@sub.site.com');
		expect(() => {parseEmail('first last@site.com');}).toThrow(EmailParseException);
	});

	test('parsing usernames', () => {
		expect(parseUsername('login')).toBe('login');
		expect(parseUsername('login123')).toBe('login123');
		expect(() => {parseUsername('@login');}).toThrow(UsernameParseException);
		expect(() => {parseUsername('1234login');}).toThrow(UsernameParseException);

		expect(parseUsername('user@site.com')).toBe('user@site.com');
		expect(parseUsername('first.last@site.com')).toBe('first.last@site.com');
		expect(parseUsername('user1234@site.com')).toBe('user1234@site.com');
		expect(parseUsername('first.last@sub.site.com')).toBe('first.last@sub.site.com');
		expect(() => {parseUsername('first last@site.com');}).toThrow(UsernameParseException);

	});
});

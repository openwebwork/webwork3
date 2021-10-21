// tests parsing and handling of users

import { MergedUser  } from '@/store/models/users';
import { NonNegIntException, EmailParseException, UsernameParseException,
	RequiredFieldsException, ParseError } from '@/store/models';

test('Create a Valid MergedUser', () => {
	const merged_user1 = new MergedUser({ username: 'test' });
	expect(merged_user1 instanceof MergedUser).toBe(true);
	const merged_user2 = new MergedUser({ username: 'test', user_id: 0, is_admin: false });
	expect(merged_user1).toStrictEqual(merged_user2);

	const merged_user_params = { username: 'test', user_id: 15 } as MergedUser;
	const merged_user = new MergedUser(merged_user_params);
	expect(merged_user instanceof MergedUser).toBe(true);

});

test('MergedUser without required fields', () => {
	expect(() => {
		new MergedUser();
	}).toThrow(RequiredFieldsException);
});

test('Invalid user_id', () => {
	expect(() => {
		new MergedUser({ username: 'test', user_id: -1 });
	}).toThrow(NonNegIntException);
	expect(() => {
		new MergedUser({ username: 'test', user_id: '-1' });
	}).toThrow(NonNegIntException);
	expect(() => {
		new MergedUser({ username: 'test', user_id: 'one' });
	}).toThrow(NonNegIntException);
});

test('Invalid username', () => {
	expect(() => {
		new MergedUser({ username: '@test' });
	}).toThrow(UsernameParseException);
	expect(() => {
		new MergedUser({ username: '123test' });
	}).toThrow(UsernameParseException);
	expect(() => {
		new MergedUser({ username: 'user name' });
	}).toThrow(UsernameParseException);
});

test('Invalid email', () => {
	expect(() => {
		new MergedUser({ username: 'test', email: 'bad email' });
	}).toThrow(EmailParseException);
	expect(() => {
		new MergedUser({ username: 'test', email: 'user@info@site.com' });
	}).toThrow(EmailParseException);
});

test('set invalid role', () => {
	const merged_user = new MergedUser({ username: 'test', role: 'student' });
	expect(() => {
		merged_user.set({ role: 'superhero' });
	}).toThrow(ParseError);
});

test('set fields of MergedUser', () => {
	const merged_user = new MergedUser({ username: 'test' });
	merged_user.set({ role: 'student' });
	expect(merged_user.role).toBe('student');

	merged_user.set({ course_id: 34 });
	expect(merged_user.course_id).toBe(34);

	merged_user.set({ user_id: 3 });
	expect(merged_user.user_id).toBe(3);

	merged_user.set({ user_id: '5' });
	expect(merged_user.user_id).toBe(5);

	merged_user.set({ section: 2 });
	expect(merged_user.section).toBe('2');

	merged_user.set({ section: '12' });
	expect(merged_user.section).toBe('12');

});

test('set invalid user_id', () => {
	const merged_user = new MergedUser({ username: 'test' });
	expect(() => {
		merged_user.set({ user_id: -1 });
	}).toThrow(NonNegIntException);

	expect(() => {
		merged_user.set({ user_id: '-1' });
	}).toThrow(NonNegIntException);

});

test('set invalid course_id', () => {
	const merged_user = new MergedUser({ username: 'test' });
	expect(() => {
		merged_user.set({ course_id: -1 });
	}).toThrow(NonNegIntException);
	expect(() => {
		merged_user.set({ course_id: '-1' });
	}).toThrow(NonNegIntException);
});

test('set invalid merged_user_id', () => {
	const merged_user = new MergedUser({ username: 'test' });
	expect(() => {
		merged_user.set({ course_user_id: -1 });
	}).toThrow(NonNegIntException);
	expect(() => {
		merged_user.set({ course_user_id: '-1' });
	}).toThrow(NonNegIntException);
});

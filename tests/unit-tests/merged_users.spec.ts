// tests parsing and handling of merged users

import { EmailParseException, NonNegIntException, UsernameParseException,
	UserRoleException } from 'src/common/models/parsers';
import { MergedUser } from 'src/common/models/users';

const default_merged_user = {
	course_user_id: 0,
	user_id: 0,
	course_id: 0,
	is_admin: false
};

test('Create a Valid MergedUser', () => {
	const merged_user1 = new MergedUser();

	expect(merged_user1 instanceof MergedUser).toBe(true);
	expect(merged_user1.toObject()).toStrictEqual(default_merged_user);

});

test('Check that calling all_fields() and params() is correct', () => {
	const merged_user_fields = ['course_user_id', 'user_id', 'course_id', 'username',
		'is_admin', 'email', 'first_name', 'last_name', 'student_id', 'role',
		'section', 'recitation'];
	const merged_user = new MergedUser();

	expect(merged_user.all_field_names.sort()).toStrictEqual(merged_user_fields.sort());
	expect(merged_user.param_fields.sort()).toStrictEqual([]);

	expect(MergedUser.ALL_FIELDS.sort()).toStrictEqual(merged_user_fields.sort());

});

test('Check that cloning a merged user works', () => {
	const merged_user = new MergedUser();
	expect(merged_user.clone().toObject()).toStrictEqual(default_merged_user);
	expect(merged_user.clone() instanceof MergedUser).toBe(true);
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
	}).toThrow(UserRoleException);
});

test('set fields of MergedUser', () => {
	const merged_user = new MergedUser({ username: 'test' });
	merged_user.set({ role: 'student' });
	expect(merged_user.role).toBe('STUDENT');

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

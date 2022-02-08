// tests parsing and handling of users

import { BooleanParseException, EmailParseException, NonNegIntException,
	UsernameParseException } from 'src/common/models/parsers';
import { RequiredFieldsException } from 'src/common/models';
import { User } from 'src/common/models/users';

const default_user = {
	user_id: 0,
	username: 'test',
	is_admin: false,
};

test('Create a default User', () => {
	const user = new User({ username: 'test' });
	expect(user instanceof User).toBe(true);
	expect(user.toObject()).toStrictEqual(default_user);

});

test('Missing Username', () => {
	// missing username
	expect(() => { new User();}).toThrow(RequiredFieldsException);
});

test('Check that calling all_fields() and params() is correct', () => {
	const user_fields = ['user_id', 'username', 'is_admin', 'email', 'first_name',
		'last_name', 'student_id'];
	const user = new User({ username: 'test' });

	expect(user.all_field_names.sort()).toStrictEqual(user_fields.sort());
	expect(user.param_fields.sort()).toStrictEqual([]);

	expect(User.ALL_FIELDS.sort()).toStrictEqual(user_fields.sort());

});

test('Check that cloning a User works', () => {
	const user = new User({ username: 'test' });
	expect(user.clone().toObject()).toStrictEqual(default_user);
	expect(user.clone() instanceof User).toBe(true);
});

test('Invalid user_id', () => {
	expect(() => {
		new User({ username: 'test', user_id: -1 });
	}).toThrow(NonNegIntException);
	expect(() => {
		new User({ username: 'test', user_id: '-1' });
	}).toThrow(NonNegIntException);
	expect(() => {
		new User({ username: 'test', user_id: 'one' });
	}).toThrow(NonNegIntException);
	expect(() => {
		new User({ username: 'test', user_id: 'false' });
	}).toThrow(NonNegIntException);
});

test('Invalid username', () => {
	expect(() => {
		new User({ username: '@test' });
	}).toThrow(UsernameParseException);
	expect(() => {
		new User({ username: '123test' });
	}).toThrow(UsernameParseException);
	expect(() => {
		new User({ username: 'user name' });
	}).toThrow(UsernameParseException);
});

test('Invalid email', () => {
	expect(() => {
		new User({ username: 'test', email: 'bad email' });
	}).toThrow(EmailParseException);
	expect(() => {
		new User({ username: 'test', email: 'user@info@site.com' });
	}).toThrow(EmailParseException);
});

test('setting user fields', () => {
	const user = new User({ username: 'test' });

	user.username = 'test2';
	expect(user.username).toBe('test2');

	user.email = 'test@site.com';
	expect(user.email).toBe('test@site.com');

	user.user_id = 15;
	expect(user.user_id).toBe(15);

	user.first_name = 'Homer';
	expect(user.first_name).toBe('Homer');

	user.last_name = 'Simpson';
	expect(user.last_name).toBe('Simpson');

	user.is_admin = true;
	expect(user.is_admin).toBe(true);

	user.is_admin = 1;
	expect(user.is_admin).toBe(true);

	user.is_admin = '0';
	expect(user.is_admin).toBe(false);

});

test('set fields using set() method', () => {
	const user = new User({ username: 'test' });

	user.set({ username: 'test2' });
	expect(user.username).toBe('test2');
	user.set({ email: 'test@site.com' });
	expect(user.email).toBe('test@site.com');

	user.set({ user_id: 15 });
	expect(user.user_id).toBe(15);

	user.set({ first_name: 'Homer' });
	expect(user.first_name).toBe('Homer');

	user.set({ last_name: 'Simpson' });
	expect(user.last_name).toBe('Simpson');

	user.set({ is_admin: true });
	expect(user.is_admin).toBe(true);

	user.set({ is_admin: 1 });
	expect(user.is_admin).toBe(true);

	user.set({ is_admin: '0' });
	expect(user.is_admin).toBe(false);
});

test('setting invalid email', () => {
	const user = new User({ username: 'test' });
	expect(() => { user.email = 'bad@email@address.com'; })
		.toThrow(EmailParseException);
});

test('setting invalid user_id', () => {
	const user = new User({ username: 'test' });
	expect(() => { user.user_id = -15; })
		.toThrow(NonNegIntException);
});

test('setting invalid admin', () => {
	const user = new User({ username: 'test' });
	expect(() => { user.is_admin = 'FALSE'; })
		.toThrow(BooleanParseException);
});

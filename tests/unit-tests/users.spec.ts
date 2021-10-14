// tests parsing and handling of users

import { BooleanParseException, EmailParseException, NonNegIntException, UsernameParseException,
	RequiredFieldsException } from '@/store/models';
import { User } from '@/store/models/users';

test('Create a Valid User', () => {
	const user1 = new User({ username: 'test' });
	expect(user1 instanceof User).toBe(true);
	const user2 = new User({ username: 'test', user_id: 0, is_admin: false });
	expect(user1).toStrictEqual(user2);

});

test('Missing Username', () => {
	// missing username
	expect(() => { new User();}).toThrow(RequiredFieldsException);
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
	expect(() => { user.set({ email: 'bad@email@address.com' }); })
		.toThrow(EmailParseException);
});

test('setting invalid user_id', () => {
	const user = new User({ username: 'test' });
	expect(() => { user.set({ user_id: -15 }); })
		.toThrow(NonNegIntException);
});

test('setting invalid admin', () => {
	const user = new User({ username: 'test' });
	expect(() => { user.set({ is_admin: 'FALSE' }); })
		.toThrow(BooleanParseException);
});

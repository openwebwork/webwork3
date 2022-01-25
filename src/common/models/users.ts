
import { parseNonNegInt, parseUsername, parseBoolean, parseEmail } from 'src/common/models/parsers';
import { RequiredFieldsException } from 'src/common/models';

export interface ParseableUser {
	user_id?: number | string;
	username?: string;
	email?: string;
	first_name?: string;
	last_name?: string;
	is_admin?: string | number | boolean;
	student_id?: string | number;
}

export class User {
	private _user_id = 0;
	private _username = '';
	private _email?: string;
	private _first_name?: string;
	private _last_name?: string;
	private _is_admin = false;
	private _student_id?: string;

	constructor(params: ParseableUser = {}) {
		this.set(params);
	}

	set(params: ParseableUser) {
		if (params.username) {
			this.username = params.username;
		} else {
			throw new RequiredFieldsException('username');
		}
		if (params.user_id) this.user_id = params.user_id;
		if (params.email) this.email = params.email;
		if (params.first_name) this.first_name = params.first_name;
		if (params.last_name) this.last_name = params.last_name;
		if (params.is_admin) this.is_admin = params.is_admin;
		if (params.student_id) this.student_id = params.student_id;
	}

	get user_id() { return this._user_id; }
	set user_id(value: number | string) {
		this._user_id = parseNonNegInt(value);
	}

	get username() { return this._username; }
	set username(value: string) {
		this._username = parseUsername(value);
	}

	get is_admin() { return this._is_admin; }
	set is_admin(value: string | number | boolean) {
		this._is_admin = parseBoolean(value);
	}

	get email(): string | undefined { return this._email; }
	set email(value: string | undefined) {
		this._email = parseEmail(value);
	}

	get first_name(): string | undefined { return this._first_name; }
	set first_name(value: string | undefined) {
		this._first_name = value;
	}

	get last_name(): string | undefined { return this._last_name; }
	set last_name(value: string | undefined) {
		this._last_name = value;
	}

	get student_id(): string | undefined { return this._student_id; }
	set student_id(value: string | number | undefined) {
		if (value) this._student_id = `${value}`;
	}
}

// tests parsing and handling of users

import { CourseSetting, DBCourseSetting, GlobalSetting, SettingType
} from 'src/common/models/settings';
import { convertTimeDuration, humanReadableTimeDuration } from 'src/common/models/parsers';

describe('Testing Course Settings', () => {
	const global_setting = {
		global_setting_id: 0,
		setting_name: '',
		default_value: '',
		category: '',
		description: '',
		type: SettingType.unknown
	};

	describe('Create a new GlobalSetting', () => {
		test('Create a default GlobalSetting', () => {
			const setting = new GlobalSetting();

			expect(setting).toBeInstanceOf(GlobalSetting);
			expect(setting.toObject()).toStrictEqual(global_setting);
		});

		test('Create a new GlobalSetting', () => {
			const global_setting = new GlobalSetting({
				global_setting_id: 10,
				setting_name: 'description',
				default_value: 'This is the description',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general'
			});

			expect(global_setting.global_setting_id).toBe(10);
			expect(global_setting.setting_name).toBe('description');
			expect(global_setting.default_value).toBe('This is the description');
			expect(global_setting.description).toBe('Describe this.');
			expect(global_setting.doc).toBe('Extended help');
			expect(global_setting.type).toBe(SettingType.text);
			expect(global_setting.category).toBe('general');
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const settings_fields = ['global_setting_id', 'setting_name', 'default_value', 'category', 'subcategory',
				'description', 'doc', 'type', 'options'];
			const setting = new GlobalSetting();

			expect(setting.all_field_names.sort()).toStrictEqual(settings_fields.sort());
			expect(setting.param_fields.sort()).toStrictEqual([]);
			expect(GlobalSetting.ALL_FIELDS.sort()).toStrictEqual(settings_fields.sort());
		});

		test('Check that cloning works', () => {
			const setting = new GlobalSetting();
			expect(setting.clone().toObject()).toStrictEqual(global_setting);
			expect(setting.clone()).toBeInstanceOf(GlobalSetting);
		});

	});

	describe('Updating global settings', () => {
		test('set fields of a global setting directly', () => {
			const global_setting = new GlobalSetting();

			global_setting.global_setting_id = 10;
			expect(global_setting.global_setting_id).toBe(10);

			global_setting.setting_name = 'description';
			expect(global_setting.setting_name).toBe('description');

			global_setting.category = 'general';
			expect(global_setting.category).toBe('general');

			global_setting.subcategory = 'problems';
			expect(global_setting.subcategory).toBe('problems');

			global_setting.default_value = 6;
			expect(global_setting.default_value).toBe(6);

			global_setting.description = 'This is the help.';
			expect(global_setting.description).toBe('This is the help.');

			global_setting.description = 'This is the extended help.';
			expect(global_setting.description).toBe('This is the extended help.');

			global_setting.type = 'int';
			expect(global_setting.type).toBe(SettingType.int);

			global_setting.type = 'undefined type';
			expect(global_setting.type).toBe(SettingType.unknown);

		});

		test('set fields of a course setting using the set method', () => {
			const global_setting = new GlobalSetting();

			global_setting.set({ global_setting_id:  25 });
			expect(global_setting.global_setting_id).toBe(25);

			global_setting.set({ setting_name: 'description' });
			expect(global_setting.setting_name).toBe('description');

			global_setting.set({ category: 'general' });
			expect(global_setting.category).toBe('general');

			global_setting.set({ subcategory: 'problems' });
			expect(global_setting.subcategory).toBe('problems');

			global_setting.set({ default_value: 6 });
			expect(global_setting.default_value).toBe(6);

			global_setting.set({ description: 'This is the help.' });
			expect(global_setting.description).toBe('This is the help.');

			global_setting.set({ doc: 'This is the extended help.' });
			expect(global_setting.doc).toBe('This is the extended help.');

			global_setting.set({ type: 'int' });
			expect(global_setting.type).toBe(SettingType.int);

			global_setting.set({ type: 'undefined type' });
			expect(global_setting.type).toBe(SettingType.unknown);

		});

	});

	describe('Test the validity of settings', () => {
		test('test the validity of settings.', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'description',
				default_value: 'This is the description',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general'
			});
			expect(global_setting.isValid()).toBe(true);

			global_setting.type = 'unknown_type';
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ type: 'list', description: '' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ description: 'This is the help.', setting_name: '' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ setting_name: 'description', category: '' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ category: 'general', doc: '', type: 'text' });
			expect(global_setting.isValid()).toBe(true);

		});

		test('test the validity of global settings for default_value type text', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'description',
				default_value: 'This is the description',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general'
			});

			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: true });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(false);
		});

		test('test the validity of global settings for default_value type int', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'number_1',
				default_value: 10,
				description: 'I am an integer',
				doc: 'Extended help',
				type: 'int',
				category: 'general'
			});

			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: 'hi' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(false);
		});

		test('test the validity of global settings for default_value type decimal', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'number_1',
				default_value: 3.14,
				description: 'I am a decimal',
				doc: 'Extended help',
				type: 'decimal',
				category: 'general'
			});

			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3 });
			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 'hi' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(false);

		});

		test('test the validity of global settings for default_value type list', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'the list',
				default_value: '1',
				description: 'I am a list',
				doc: 'Extended help',
				type: 'list',
				category: 'general'
			});

			// The options are missing
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ options: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: 'hi' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(false);

			// Test the options with label/values
			global_setting.set({ options: [
				{ label: 'label1', value: '1' },
				{ label: 'label2', value: '2' },
				{ label: 'label3', value: '3' },
			], default_value: '2' });
			expect(global_setting.isValid()).toBe(true);
		});

		test('test the validity of global settings for default_value type multilist', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'my_multilist',
				default_value: ['1', '2'],
				description: 'I am a multilist',
				doc: 'Extended help',
				type: 'multilist',
				category: 'general'
			});

			// The options is missing, so not valid.
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ options: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: 'hi' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '4'] });
			expect(global_setting.isValid()).toBe(false);

			// Test the options in the form label/value
			global_setting.set({
				options: [
					{ label: 'option 1', value: '1' },
					{ label: 'option 2', value: '2' },
					{ label: 'option 3', value: '3' },
				],
				default_value: ['1', '3']
			});
			expect(global_setting.isValid()).toBe(true);

		});

		test('test the validity of global settings for default_value type boolean', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'a_boolean',
				default_value: true,
				description: 'I am true or false',
				doc: 'Extended help',
				type: 'boolean',
				category: 'general'
			});

			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: 3 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['1', '2', '3'] });
			expect(global_setting.isValid()).toBe(false);
		});

		test('test the validity of global settings for default_value type boolean', () => {
			const global_setting = new GlobalSetting();
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({
				setting_name: 'time_due',
				default_value: '23:59',
				description: 'The time that is due',
				doc: 'Extended help',
				type: 'time',
				category: 'general'
			});

			expect(global_setting.isValid()).toBe(true);

			global_setting.set({ default_value: 3.14 });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: '31:45' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: '13:65' });
			expect(global_setting.isValid()).toBe(false);

			global_setting.set({ default_value: ['23:45'] });
			expect(global_setting.isValid()).toBe(false);
		});

	});

	const default_db_setting = {
		course_setting_id: 0,
		course_id: 0,
		global_setting_id: 0
	};

	describe('Create a new DBCourseSetting', () => {
		test('Create a default DBCourseSetting', () => {
			const setting = new DBCourseSetting();

			expect(setting).toBeInstanceOf(DBCourseSetting);
			expect(setting.toObject()).toStrictEqual(default_db_setting);
		});

		test('Create a new GlobalSetting', () => {
			const course_setting = new DBCourseSetting({
				course_setting_id: 10,
				course_id: 34,
				global_setting_id: 199,
				value: 'xyz'
			});

			expect(course_setting.course_setting_id).toBe(10);
			expect(course_setting.course_id).toBe(34);
			expect(course_setting.global_setting_id).toBe(199);
			expect(course_setting.value).toBe('xyz');
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const settings_fields = ['course_setting_id', 'global_setting_id', 'course_id', 'value'];
			const setting = new DBCourseSetting();

			expect(setting.all_field_names.sort()).toStrictEqual(settings_fields.sort());
			expect(setting.param_fields.sort()).toStrictEqual([]);
			expect(DBCourseSetting.ALL_FIELDS.sort()).toStrictEqual(settings_fields.sort());
		});

		test('Check that cloning works', () => {
			const setting = new DBCourseSetting();
			expect(setting.clone().toObject()).toStrictEqual(default_db_setting);
			expect(setting.clone()).toBeInstanceOf(DBCourseSetting);
		});

	});

	describe('Updating db course settings', () => {
		test('set fields of a db course setting directly', () => {
			const course_setting = new DBCourseSetting();
			course_setting.course_setting_id = 10;
			expect(course_setting.course_setting_id).toBe(10);

			course_setting.global_setting_id = 25;
			expect(course_setting.global_setting_id).toBe(25);

			course_setting.course_id = 15;
			expect(course_setting.course_id).toBe(15);

			course_setting.value = 6;
			expect(course_setting.value).toBe(6);
		});

		test('set fields of a course setting using the set method', () => {
			const course_setting = new DBCourseSetting();

			course_setting.set({ course_setting_id:  10 });
			expect(course_setting.course_setting_id).toBe(10);

			course_setting.set({ global_setting_id:  25 });
			expect(course_setting.global_setting_id).toBe(25);

			course_setting.set({ course_id:  15 });
			expect(course_setting.course_id).toBe(15);

			course_setting.set({ value: 6 });
			expect(course_setting.value).toBe(6);
		});
	});

	const default_course_setting = {
		global_setting_id: 0,
		course_id: 0,
		course_setting_id: 0,
		setting_name: '',
		default_value: '',
		category: '',
		description: '',
		value: '',
		type: SettingType.unknown
	};

	describe('Create a new CourseSetting', () => {
		test('Create a default CourseSetting', () => {
			const setting = new CourseSetting();

			expect(setting).toBeInstanceOf(CourseSetting);
			expect(setting.toObject()).toStrictEqual(default_course_setting);
		});

		test('Create a new CourseSetting', () => {
			const course_setting = new CourseSetting({
				global_setting_id: 10,
				course_id: 5,
				course_setting_id: 17,
				value: 'this is my value',
				setting_name: 'description',
				default_value: 'This is the description',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general'
			});

			expect(course_setting.global_setting_id).toBe(10);
			expect(course_setting.course_id).toBe(5);
			expect(course_setting.course_setting_id).toBe(17);
			expect(course_setting.value).toBe('this is my value');
			expect(course_setting.setting_name).toBe('description');
			expect(course_setting.default_value).toBe('This is the description');
			expect(course_setting.description).toBe('Describe this.');
			expect(course_setting.doc).toBe('Extended help');
			expect(course_setting.type).toBe(SettingType.text);
			expect(course_setting.category).toBe('general');
		});

		test('Check that calling all_fields() and params() is correct', () => {
			const settings_fields = ['global_setting_id', 'course_setting_id', 'course_id', 'value', 'setting_name',
				'default_value', 'category', 'subcategory', 'description', 'doc', 'type', 'options'];
			const setting = new CourseSetting();

			expect(setting.all_field_names.sort()).toStrictEqual(settings_fields.sort());
			expect(setting.param_fields.sort()).toStrictEqual([]);
			expect(CourseSetting.ALL_FIELDS.sort()).toStrictEqual(settings_fields.sort());
		});

		test('Check that cloning works', () => {
			const setting = new CourseSetting();
			expect(setting.clone().toObject()).toStrictEqual(default_course_setting);
			expect(setting.clone()).toBeInstanceOf(CourseSetting);
		});

	});

	describe('Updating course settings', () => {
		test('set fields of a course setting directly', () => {
			const course_setting = new CourseSetting();

			course_setting.global_setting_id = 25;
			expect(course_setting.global_setting_id).toBe(25);

			course_setting.course_id = 15;
			expect(course_setting.course_id).toBe(15);

			course_setting.value = 6;
			expect(course_setting.value).toBe(6);

			course_setting.setting_name = 'description';
			expect(course_setting.setting_name).toBe('description');

			course_setting.category = 'general';
			expect(course_setting.category).toBe('general');

			course_setting.subcategory = 'problems';
			expect(course_setting.subcategory).toBe('problems');

			course_setting.default_value = 6;
			expect(course_setting.default_value).toBe(6);

			course_setting.description = 'This is the help.';
			expect(course_setting.description).toBe('This is the help.');

			course_setting.doc = 'This is the extended help.';
			expect(course_setting.doc).toBe('This is the extended help.');

			course_setting.type = 'int';
			expect(course_setting.type).toBe(SettingType.int);

			course_setting.type = 'undefined type';
			expect(course_setting.type).toBe(SettingType.unknown);

		});

		test('set fields of a course setting using the set method', () => {
			const course_setting = new CourseSetting();

			course_setting.set({ course_setting_id:  10 });
			expect(course_setting.course_setting_id).toBe(10);

			course_setting.set({ global_setting_id:  25 });
			expect(course_setting.global_setting_id).toBe(25);

			course_setting.set({ course_id:  15 });
			expect(course_setting.course_id).toBe(15);

			course_setting.set({ value: 6 });
			expect(course_setting.value).toBe(6);

			course_setting.set({ global_setting_id:  25 });
			expect(course_setting.global_setting_id).toBe(25);

			course_setting.set({ setting_name: 'description' });
			expect(course_setting.setting_name).toBe('description');

			course_setting.set({ category: 'general' });
			expect(course_setting.category).toBe('general');

			course_setting.set({ subcategory: 'problems' });
			expect(course_setting.subcategory).toBe('problems');

			course_setting.set({ default_value: 6 });
			expect(course_setting.default_value).toBe(6);

			course_setting.set({ description: 'This is the help.' });
			expect(course_setting.description).toBe('This is the help.');

			course_setting.set({ doc: 'This is the extended help.' });
			expect(course_setting.doc).toBe('This is the extended help.');

			course_setting.set({ type: 'int' });
			expect(course_setting.type).toBe(SettingType.int);

			course_setting.set({ type: 'undefined type' });
			expect(course_setting.type).toBe(SettingType.unknown);

		});

	});

	describe('Test to determine that course settings overrides are working', () => {
		test('Test to determine that course settings overrides are working', () => {
			// If the Course Setting value is defined, then the value should be that.
			// If instead the value is undefined, use the default_value.

			const course_setting = new CourseSetting({
				global_setting_id: 10,
				course_id: 5,
				course_setting_id: 17,
				setting_name: 'description',
				default_value: 'This is the default value',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general'
			});

			expect(course_setting.value).toBe('This is the default value');

			course_setting.value = 'This is the value.';
			expect(course_setting.value).toBe('This is the value.');
		});
	});

	describe('Test the validity of course settings', () => {
		test('test the basic validity of course settings.', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'description',
				default_value: 'This is the description',
				description: 'Describe this.',
				doc: 'Extended help',
				type: 'text',
				category: 'general',
				value: 'my value'
			});
			expect(course_setting.isValid()).toBe(true);

			course_setting.type = 'unknown_type';
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ type: 'text', description: '' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ description: 'This is the help.', setting_name: '' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ setting_name: 'description', category: '' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ category: 'general', doc: '' });
			expect(course_setting.isValid()).toBe(true);

		});

		test('test the validity of course settings for default_value type int', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'number_1',
				default_value: 10,
				description: 'I am an integer',
				doc: 'Extended help',
				type: 'int',
				category: 'general'
			});

			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3.14 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: 'hi' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(false);
		});

		test('test the validity of course settings for default_value type decimal', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'number_1',
				default_value: 3.14,
				description: 'I am a decimal',
				doc: 'Extended help',
				type: 'decimal',
				category: 'general'
			});

			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3 });
			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 'hi' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(false);
		});

		test('test the validity of course settings for default_value type list', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'the list',
				default_value: '1',
				description: 'I am a list',
				doc: 'Extended help',
				type: 'list',
				category: 'general'
			});

			// The options are missing
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ options: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3.14 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: 'hi' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(false);
		});

		test('test the validity of course settings for default_value type multilist', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'my_multilist',
				default_value: ['1', '2'],
				description: 'I am a multilist',
				doc: 'Extended help',
				type: 'multilist',
				category: 'general'
			});

			// The options is missing, so not valid.
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ options: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3.14 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: 'hi' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '4'] });
			expect(course_setting.isValid()).toBe(false);

			// Test the options in the form label/value
			course_setting.set({
				options: [
					{ label: 'option 1', value: '1' },
					{ label: 'option 2', value: '2' },
					{ label: 'option 3', value: '3' },
				]
			});
			expect(course_setting.isValid()).toBe(true);

		});

		test('test the validity of course settings for default_value type boolean', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'a_boolean',
				default_value: true,
				description: 'I am true or false',
				doc: 'Extended help',
				type: 'boolean',
				category: 'general'
			});

			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3.14 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: 3 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(false);
		});

		test('test the validity of course settings for default_value type time_duration', () => {
			const course_setting = new CourseSetting();
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({
				setting_name: 'time_duration',
				default_value: 1234,
				description: 'I am an time interval',
				doc: 'Extended help',
				type: 'time_duration',
				category: 'general'
			});

			expect(course_setting.isValid()).toBe(true);

			course_setting.set({ value: 3.14 });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: '3 days' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: 'hi' });
			expect(course_setting.isValid()).toBe(false);

			course_setting.set({ value: ['1', '2', '3'] });
			expect(course_setting.isValid()).toBe(false);
		});

	});

	describe('Test converting of human readable time duration to number of seconds', () => {
		test('Test time duration of seconds', () => {
			expect(convertTimeDuration('1 sec')).toBe(1);
			expect(convertTimeDuration('15 secs')).toBe(15);
		});

		test('Test time duration of mins', () => {
			expect(convertTimeDuration('1 min')).toBe(60);
			expect(convertTimeDuration('5 mins')).toBe(5 * 60);
			expect(convertTimeDuration('5 mins, 30 secs')).toBe(5 * 60 + 30);
		});

		test('Test time duration of hours', () => {
			expect(convertTimeDuration('1 hour')).toBe(1 * 60 * 60);
			expect(convertTimeDuration('1 hr')).toBe(1 * 60 * 60);
			expect(convertTimeDuration('5 hours')).toBe(5 * 60 * 60);
			expect(convertTimeDuration('3 hrs')).toBe(3 * 60 * 60);
			expect(convertTimeDuration('3 hrs, 10 mins, 15 seconds')).toBe(3 * 60 * 60 + 10 * 60 + 15);
		});

		test('Test time duration of days', () => {
			expect(convertTimeDuration('1 day')).toBe(1 * 24 * 60 * 60);
			expect(convertTimeDuration('3 days')).toBe(3 * 24 * 60 * 60);
			expect(convertTimeDuration('3 days, 12 hours')).toBe(3 * 24 * 60 * 60 + 12 * 60 * 60);
		});

		test('Test time duration of weeks', () => {
			expect(convertTimeDuration('1 week')).toBe(1 * 7 * 24 * 60 * 60);
			expect(convertTimeDuration('2 weeks')).toBe(2 * 7 * 24 * 60 * 60);
			expect(convertTimeDuration('2 weeks, 5 days')).toBe(2 * 7 * 24 * 60 * 60 + 5 * 24 * 60 * 60);
		});

	});

	describe('Test conversion of num. seconds to human readable time durations', () => {
		test('Test time duration of secs', () => {
			expect(humanReadableTimeDuration(0)).toBe('');
			expect(humanReadableTimeDuration(1)).toBe('1 sec');
			expect(humanReadableTimeDuration(15)).toBe('15 secs');
		});

		test('Test time duration of mins', () => {
			expect(humanReadableTimeDuration(60)).toBe('1 min');
			expect(humanReadableTimeDuration(5 * 60)).toBe('5 mins');
			expect(humanReadableTimeDuration(5 * 60 + 30)).toBe('5 mins, 30 secs');
		});

		test('Test time duration of hours', () => {
			expect(humanReadableTimeDuration(3600)).toBe('1 hour');
			expect(humanReadableTimeDuration(5 * 3600)).toBe('5 hours');
			expect(humanReadableTimeDuration(5 * 3600 + 30 * 60)).toBe('5 hours, 30 mins');
		});

		test('Test time duration of days', () => {
			expect(humanReadableTimeDuration(3600 * 24)).toBe('1 day');
			expect(humanReadableTimeDuration(3 * 3600 * 24)).toBe('3 days');
			expect(humanReadableTimeDuration(3 * 3600 * 24 + 6 * 3600)).toBe('3 days, 6 hours');
			expect(humanReadableTimeDuration(3 * 3600 * 24 + 6 * 3600 + 30 * 60)).toBe('3 days, 6 hours, 30 mins');
		});

		test('Test time duration of weeks', () => {
			expect(humanReadableTimeDuration(3600 * 24 * 7)).toBe('1 week');
			expect(humanReadableTimeDuration(3600 * 24 * 7 * 2)).toBe('2 weeks');
			expect(humanReadableTimeDuration(3600 * 24 * 7 * 2 + 3 * 3600 * 24)).toBe('2 weeks, 3 days');
		});
	});
});

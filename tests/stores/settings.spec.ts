/**
 * @jest-environment jsdom
 */
// The above is needed because  1) the logger uses the window object, which is only present
// when using the jsdom environment and 2) because the pinia store is used is being
// tested with persistance.

// settings.spec.ts
// Test the Settings Store

import { createApp } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

import fs from 'fs';
import { parse } from 'yaml';

import { api } from 'boot/axios';

import { useSessionStore } from 'src/stores/session';
import { useSettingsStore } from 'src/stores/settings';
import { DBCourseSetting, ParseableDBCourseSetting, ParseableGlobalSetting, SettingValueType
} from 'src/common/models/settings';

import { cleanIDs, loadCSV } from '../utils';

describe('Test the settings store', () => {

	const app = createApp({});
	let default_settings: ParseableGlobalSetting[];
	let arith_settings: {setting_name: string; value: SettingValueType}[];
	beforeAll(async () => {
		// Since we have the piniaPluginPersistedState as a plugin, duplicate for the test.
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);

		setActivePinia(pinia);

		// Load the default settings
		const file = fs.readFileSync('conf/course_settings.yml', 'utf8');
		default_settings = parse(file) as ParseableGlobalSetting[];

		// Fetch the course settings from the CSV file
		const course_settings = await loadCSV('t/db/sample_data/course_settings.csv', {});
		arith_settings = course_settings.filter(setting => setting['course_name'] === 'Arithmetic')
			.map(setting => ({
				setting_name: setting.setting_name as string, value: setting.setting_value as SettingValueType
			}));
		// Login to the course as the admin in order to be authenticated for the rest of the test.
		await api.post('login', { username: 'admin', password: 'admin' });

		const settings_store = useSettingsStore();
		await settings_store.fetchGlobalSettings();

	});

	describe('Check the global settings', () => {

		test('Check the default settings', () => {
			const settings_store = useSettingsStore();
			expect(cleanIDs(settings_store.global_settings)).toStrictEqual(default_settings);
		});

		test('Make sure the settings are valid.', () => {
			const settings_store = useSettingsStore();
			settings_store.global_settings.forEach(setting => {
				expect(setting.isValid()).toBe(true);
			});
		});

	});

	describe('Get all course settings and individual course settings', () => {

		test('Get the course settings for a course', async () => {
			const settings_store = useSettingsStore();
			// The arithmetic course has course_id: 4
			await settings_store.fetchCourseSettings(4);
			const arith_setting_ids = settings_store.db_course_settings.map(setting => setting.setting_id);

			const arith_settings_from_db = settings_store.course_settings
				.filter(setting => arith_setting_ids.includes(setting.setting_id))
				.map(setting => ({ setting_name: setting.setting_name, value: setting.value }));
			expect(arith_settings_from_db).toStrictEqual(arith_settings);

			// set the session course to this course
			const session_store = useSessionStore();
			session_store.setCourse({ course_id: 4, course_name: 'Arithmetic' });
		});

		test('Get a single course setting based on name', () => {
			const settings_store = useSettingsStore();
			const timezone_setting = settings_store.getCourseSetting('timezone');
			const timezone_from_file = arith_settings.find(setting => setting.setting_name === 'timezone');
			expect(timezone_setting.value).toBe(timezone_from_file?.value);
		});

		test('Ensure that getting a non-existant setting throws an error', () => {
			const settings_store = useSettingsStore();
			expect(() => {
				settings_store.getCourseSetting('non_existant_setting');
			}).toThrowError('The setting with name: \'non_existant_setting\' does not exist.');
		});
	});

	describe('Update a Course Setting', () => {
		test('Update a setting', async () => {
			const settings_store = useSettingsStore();
			const setting = settings_store.getCourseSetting('course_description');
			setting.value = 'this is a new description';
			const updated_setting = await settings_store.updateCourseSetting(setting);
			expect(updated_setting.value).toBe(setting.value);
		});

		test('Make sure the updated settings are synched with the database', async () => {
			const settings_store = useSettingsStore();
			const settings_in_store = settings_store.db_course_settings.map(setting => ({
				value: setting.value,
				course_setting_id: setting.course_setting_id,
				setting_id: setting.setting_id,
				course_id: setting.course_id
			}));
			const response = await api.get('/courses/4/settings');
			const settings_from_db = (response.data as ParseableDBCourseSetting[])
				.map(setting => new DBCourseSetting(setting));
			expect(settings_in_store).toStrictEqual(settings_from_db.map(s => s.toObject()));
		});
	});

	describe('Deleting a Course Setting', () => {
		test('Update a setting', async () => {
			const settings_store = useSettingsStore();
			const setting = settings_store.getCourseSetting('course_description');
			const deleted_setting = await settings_store.deleteCourseSetting(setting);
			expect(deleted_setting.value).toBe('this is a new description');

		});
	});

});

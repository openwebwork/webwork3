import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { useSessionStore } from 'src/stores/session';
import { CourseSetting, DBCourseSetting, GlobalSetting, ParseableDBCourseSetting,
	ParseableGlobalSetting } from 'src/common/models/settings';

export interface SettingsState {
	// These are the default setting and documentation
	global_settings: Array<GlobalSetting>;
	// This are the specific settings for the course as from the database.
	db_course_settings: Array<DBCourseSetting>;
}

export const useSettingsStore = defineStore('settings', {
	state: (): SettingsState => ({
		global_settings: [],
		db_course_settings: []
	}),
	getters: {
		/**
		 *  This is an array of all settings in the course.  If the setting has been changed
		 * from the default, that setting is used, if not, used the default/global setting.
		 */
		course_settings: (state): CourseSetting[] => state.global_settings.map(global_setting => {
			const db_setting = state.db_course_settings
				.find(setting => setting.setting_id === global_setting.setting_id);
			return new CourseSetting(Object.assign(db_setting?.toObject() ?? {}, global_setting.toObject()));
		}),
		/**
		 * This returns the course setting by name.
		 */
		getCourseSetting: (state) => (setting_name: string): CourseSetting => {
			const global_setting = state.global_settings.find(setting => setting.setting_name === setting_name);
			if (global_setting) {
				const db_course_setting = state.db_course_settings
					.find(setting => setting.setting_id === global_setting?.setting_id);
				return new CourseSetting(Object.assign(
					db_course_setting?.toObject() ?? {},
					global_setting?.toObject()));
			} else {
				throw `The setting with name: '${setting_name}' does not exist.`;
			}
		},
		/**
		 * This returns the value of the setting in the course.  If the setting has been
		 * changed from the default, that value is used, if not the default value is used.
		 */
		// Note: using standard function notation (not arrow) due to using this.
		getSettingValue() {
			return (setting_name: string) => {
				const course_setting = this.getCourseSetting(setting_name);
				return course_setting.value;
			};
		},
	},
	actions: {
		async fetchGlobalSettings(): Promise<void> {
			const response = await api.get('global-settings');
			this.global_settings = (response.data as Array<ParseableGlobalSetting>).map(setting =>
				new GlobalSetting(setting));
		},
		async fetchCourseSettings(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/settings`);

			this.db_course_settings = (response.data as ParseableDBCourseSetting[]).map(setting =>
				new DBCourseSetting(setting));
		},
		async updateCourseSetting(course_setting: CourseSetting): Promise<CourseSetting> {
			const session = useSessionStore();
			const course_id = session.course.course_id;

			// Send only the database course setting fields.
			const response = await api.put(`/courses/${course_id}/settings/${course_setting.setting_id}`,
				course_setting.toObject(DBCourseSetting.ALL_FIELDS));
			const updated_setting = new DBCourseSetting(response.data as ParseableDBCourseSetting);

			// update the store
			const i = this.db_course_settings.findIndex(setting => setting.setting_id === updated_setting.setting_id);
			if (i >= 0) {
				this.db_course_settings.splice(i, 1, updated_setting);
			} else {
				this.db_course_settings.push(updated_setting);
			}
			const global_setting = this.global_settings
				.find(setting => setting.setting_id === updated_setting.setting_id);

			return new CourseSetting(Object.assign(updated_setting.toObject(), global_setting?.toObject()));
		},
		/**
		 * Deletes the course setting from both the store and sends a delete request to the database.
		 */
		async deleteCourseSetting(course_setting: CourseSetting): Promise<CourseSetting> {
			const session = useSessionStore();
			const course_id = session.course.course_id;

			const i = this.db_course_settings.findIndex(setting => setting.setting_id == course_setting.setting_id);
			if (i < 0) {
				throw `The setting with name: '${course_setting.setting_name}' has not been defined for this course.`;
			}
			const response = await api.delete(`/courses/${course_id}/settings/${course_setting.setting_id}`);
			this.db_course_settings.splice(i, 1);
			const deleted_setting = new DBCourseSetting(response.data as ParseableDBCourseSetting);
			return new CourseSetting(Object.assign(deleted_setting.toObject(), course_setting.toObject()));
		},
		/**
		 * Used to clear out all of the settings.  Useful when logging out.
		 */
		clearAll() {
			this.global_settings = [];
			this.db_course_settings = [];
		}
	}
});

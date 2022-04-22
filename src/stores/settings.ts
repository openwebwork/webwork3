import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import { useSessionStore } from 'src/stores/session';
import type { CourseSettingInfo } from 'src/common/models/settings';
import { CourseSetting, CourseSettingOption } from 'src/common/models/settings';
import { Dictionary } from 'src/common/models';

// This is the structure that settings come back from the server
type SettingValue = string | number | boolean | string[];
interface SettingsObject {
	general: Dictionary<SettingValue>;
	optional: Dictionary<SettingValue>;
	permission: Dictionary<SettingValue>;
	problem_set: Dictionary<SettingValue>;
	problem: Dictionary<SettingValue>;
	email: Dictionary<SettingValue>;
}

export interface SettingsState {
	default_settings: Array<CourseSettingInfo>; // this contains default setting and documentation
	course_settings: Array<CourseSetting>; // this is the specific settings for the course
}

export const useSettingsStore = defineStore('settings', {
	state: (): SettingsState => ({
		default_settings: [],
		course_settings: []
	}),
	actions: {
		async fetchDefaultSettings(): Promise<void> {
			const response = await api.get('default_settings');
			this.default_settings = response.data as Array<CourseSettingInfo>;
		},
		async fetchCourseSettings(course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/settings`);
			// switch boolean values to javascript true/false
			const course_settings = response.data as CourseSetting[];
			course_settings.forEach((setting: CourseSetting) => {
				const found_setting = this.default_settings.find(
					(_setting: CourseSettingInfo) => _setting.var === setting.var
				);
				if (found_setting && found_setting.type === CourseSettingOption.boolean) {
					setting.value = setting.value === 1 ? true : false;
				}
			});
			this.course_settings = course_settings;
		},
		getCourseSetting(var_name: string): CourseSetting {
			const setting = this.course_settings.find((_setting: CourseSetting) => _setting.var === var_name);
			return setting || new CourseSetting({});
		},
		async updateCourseSetting(params: { var: string; value: string | number | boolean | string[] }):
			Promise<CourseSetting> {
			const session = useSessionStore();
			const course_id = session.course.course_id;
			const setting = this.default_settings.find(s => s.var === params.var);

			// Build the setting as a object for the API.
			const setting_to_update: Dictionary<Dictionary<string | number | boolean | string[]>> = {};
			const s: Dictionary<string | number | boolean | string[]> = {};
			s[params.var] = params.value;
			setting_to_update[setting?.category || ''] = s;
			const response = await api.put(`/courses/${course_id}/setting`, setting_to_update);
			const updated_settings = response.data as SettingsObject;
			const setting_value = updated_settings[setting?.category as keyof SettingValue][params.var];
			const updated_setting = new CourseSetting({ var: params.var, value: setting_value });
			// update the store
			const i = this.course_settings.findIndex(s => s.var === params.var);
			if (i >= 0) {
				this.course_settings.splice(i, 1, updated_setting);
			}
			return updated_setting;
		},
		clearAll() {
			this.course_settings = [];
			this.default_settings = [];
		}
	}
});

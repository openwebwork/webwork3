import { api } from 'boot/axios';
import { defineStore } from 'pinia';

import type { CourseSettingInfo } from 'src/common/models/settings';
import { CourseSetting, CourseSettingOption } from 'src/common/models/settings';

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
		}

	}
});

import { api } from 'boot/axios';
import type { Commit, GetterTree } from 'vuex';
import type { StateInterface } from 'src/store';
import type { CourseSettingInfo } from 'src/store/models/settings';
import { CourseSetting } from 'src/store/models/settings';
import { CourseSettingOption } from 'src/store/models/settings';

export interface SettingsState {
	default_settings: Array<CourseSettingInfo>; // this contains default setting and documentation
	course_settings: Array<CourseSetting>; // this is the specific settings for the course
}

function state(): SettingsState {
	return {
		default_settings: [],
		course_settings: []
	};
}

type Getters = {
	default_settings(state: SettingsState): Array<CourseSettingInfo>;
	course_settings(state: SettingsState): Array<CourseSetting>;
	get_setting_value(state: SettingsState): (var_name: string) => CourseSetting['value'];
};

const getters: GetterTree<SettingsState, StateInterface> & Getters = {
	course_settings: (state) => state.course_settings,
	default_settings: (state) => state.default_settings,
	get_setting_value: (state) => (var_name: string) =>
		state.course_settings.find((setting: CourseSetting) => setting.var === var_name)?.value ?? ''
};

export default {
	namespaced: true,
	getters,
	actions: {
		async fetchDefaultSettings({ commit }: { commit: Commit }): Promise<void> {
			const response = await api.get('default_settings');
			commit('SET_DEFAULT_SETTINGS', response.data as Array<CourseSettingInfo>);
		},
		async fetchCourseSettings({ commit }: { commit: Commit }, course_id: number): Promise<void> {
			const response = await api.get(`courses/${course_id}/settings`);
			commit('SET_COURSE_SETTINGS', response.data as Array<CourseSetting>);
		},
		getCurrentSetting({ state }: { state: SettingsState}, _var: string): CourseSetting {
			const setting = state.course_settings.find((_setting: CourseSetting) => _setting.var === _var);
			return setting || new CourseSetting({});
		}

	},
	mutations: {
		SET_DEFAULT_SETTINGS(state: SettingsState, _default_settings: Array<CourseSettingInfo>): void {
			state.default_settings = _default_settings;
		},
		SET_COURSE_SETTINGS(state: SettingsState, _course_settings: Array<CourseSetting>): void {
			// switch boolean values to javascript true/false
			_course_settings.forEach((setting: CourseSetting) => {
				const found_setting = state.default_settings.find(
					(_setting: CourseSettingInfo) => _setting.var === setting.var
				);
				if (found_setting && found_setting.type === CourseSettingOption.boolean) {
					setting.value = setting.value === 1 ? true : false;
				}
			});
			state.course_settings = _course_settings;
		}
	},
	state
};

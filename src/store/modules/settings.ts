import axios from 'axios';

import { Commit, GetterTree } from 'vuex';
import { StateInterface } from '../index';
import { CourseSetting, CourseSettingInfo } from '../models';


export interface SettingsState {
	default_settings: Array<CourseSettingInfo>;  // this contains default setting and documentation
	course_settings: Array<CourseSetting>; // this is the specific settings for the course
}

function state(): SettingsState {
	return {
		default_settings: [],
		course_settings: []
	}
}

type Getters = {
	default_settings(state: SettingsState) : Array<CourseSettingInfo>;
	course_settings(state: SettingsState) : Array<CourseSetting>;
}

const getters: GetterTree<SettingsState,StateInterface> & Getters = {
	course_settings: state => state.course_settings,
	default_settings: state => state.default_settings
}

export default {
	namespaced: true,
	getters,
  actions: {
    async fetchDefaultSettings( { commit }: { commit: Commit }): Promise<void> {
			const response = await axios.get('/webwork3/api/default_settings');
			commit('SET_DEFAULT_SETTINGS',response.data as Array<CourseSettingInfo>);
		},
		async fetchCourseSettings( { commit }: { commit: Commit }): Promise<void> {
			const response = await axios.get('/webwork3/api/settings');
			commit('SET_DEFAULT_SETTINGS',response.data as Array<CourseSettingInfo>);
		},
		logout( { commit }: {commit: Commit }): void {
			commit('UPDATE_SESSION_INFO',{ logged_in: false});
			commit('SET_COURSE_NAME','');
		}
	},
  mutations: {
		SET_DEFAULT_SETTINGS(state: SettingsState, _default_settings: Array<CourseSettingInfo>): void {
			state.default_settings = _default_settings;
		},
		SET_COURSE_SETTINGS(state: SettingsState, _course_settings: Array<CourseSetting>): void {
			state.course_settings = _course_settings;
		},
	},
	state
};

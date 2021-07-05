import { LoginInfo, User } from "../models";
import { Commit } from 'vuex';

interface State {
	logged_in: boolean;
	user: User;
	course_name: string;
}

const initial_state = {
	user: {
		email: "",
		first_name: "",
		is_admin: 0,
		last_name: "",
		login: "",
		student_id: "",
		user_id: 0
	},
	logged_in: false,
	course_name: "",
}

export const sessionModule = {
  namespaced: true,
  state: initial_state,
	getters: {
		logged_in (state: State): boolean{
			return state.logged_in;
		},
		user (state: State): User {
			return state.user;
		},
		course_name (state: State): string {
			return state.course_name;
		}
	},
  actions: {
    updateLoginInfo( { commit }: { commit: Commit }, login_info: LoginInfo): void {
			commit('updateLoginInfo',login_info);
		},
		setCourseName( { commit }: { commit: Commit }, _course_name: string): void {
			commit('setCourseName',_course_name);
		}
	},
  mutations: {
		updateLoginInfo(state: State, _login_info: LoginInfo): void {
			state.logged_in = _login_info.logged_in;
			if (state.logged_in) {
				state.user = _login_info.user;
			}
		},
		setCourseName(state: State, _course_name: string): void {
			state.course_name = _course_name;
		}
	}
};
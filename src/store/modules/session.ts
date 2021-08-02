import { Commit, GetterTree } from 'vuex';
import { StateInterface } from '../index';
import { User, SessionInfo } from '../models';
import { newUser } from '../common';
// import { Session } from 'inspector';

interface CourseInfo {
	course_name: string;
	course_id: number;
}

export interface SessionState {
	logged_in: boolean;
	user: User;
	course: CourseInfo;
}

function state(): SessionState {
	return {
		logged_in: false,
		user: newUser(),
		course: {
			course_id: 0,
			course_name: ''
		}
	}
}

type Getters = {
	logged_in(state: SessionState) : boolean;
	user(state: SessionState): User;
	full_name(state: SessionState): string;
	course(state: SessionState): CourseInfo;
}

const getters: GetterTree<SessionState,StateInterface> & Getters = {
	logged_in: state => state.logged_in,
	user: state => state.user,
	full_name: state => {
		return state.user.first_name + ' ' + state.user.last_name;
	},
	course: state => state.course,
}

export default {
	namespaced: true,
	getters,
  actions: {
    updateSessionInfo( { commit }: { commit: Commit }, session_info: SessionInfo): void {
			commit('UPDATE_SESSION_INFO',session_info);
		},
		setCourse( { commit }: { commit: Commit }, _course: CourseInfo): void {
			console.log(_course);
			commit('SET_COURSE',_course);
		},
		logout( { commit }: {commit: Commit }): void {
			commit('UPDATE_SESSION_INFO',{ logged_in: false});
			commit('SET_COURSE','');
		}
	},
  mutations: {
		UPDATE_SESSION_INFO(state: SessionState, _session_info: SessionInfo): void {
			state.logged_in = _session_info.logged_in;
			if (state.logged_in) {
				state.user = _session_info.user;
			} else {
				state.user = newUser()
			}
		},
		SET_COURSE(state: SessionState, _course: CourseInfo): void {
			state.course = _course;
		}
	},
	state
};

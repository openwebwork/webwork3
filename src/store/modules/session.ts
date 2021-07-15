import { Commit, GetterTree } from 'vuex';
import { StateInterface } from '../index';
import { User, SessionInfo } from '../models';
import { newUser } from '../common';
// import { Session } from 'inspector';


export interface SessionState {
	logged_in: boolean;
	user: User;
	course_name: string;
}

function state(): SessionState {
	return {
		logged_in: false,
		user: newUser(),
		course_name: ''
	}
}

// interface SessionGetters {
// 	'session/logged_in': boolean;
// 	'session/user': User;
// 	'session/course_name': string;
// }

// /* Getter names */
// export  enum  GetterTypes  {
// 	GET_LOGGED_IN   = 'session/logged_in',
// 	GET_USER        = 'session/user',
// 	GET_COURSE_NAME = 'session/course_name'
// }

type Getters = {
	logged_in(state: SessionState) : boolean;
	user(state: SessionState): User;
	full_name(state: SessionState): string;
	course_name(state: SessionState): string;
}

const getters: GetterTree<SessionState,StateInterface> & Getters = {
	logged_in: state => state.logged_in,
	user: state => state.user,
	full_name: state => {
		return state.user.first_name + ' ' + state.user.last_name;
	},
	course_name: state => state.course_name,
}

// type Getters = {
//   [P in keyof SessionGetters]: (state: SessionState, getters: SessionGetters) => SessionGetters[P];
// }

// const getters: GetterTree<SessionState, StateInterface> & Getters = {
// 	[GetterTypes.GET_LOGGED_IN]: (state: SessionState): boolean  => {
// 		return state.logged_in;
// 	},
// 	[GetterTypes.GET_USER]: (state: SessionState): User => {
// 		return state.user;
// 	},
// 	[GetterTypes.GET_COURSE_NAME]: (state: SessionState): string => {
// 		return state.course_name;
// 	}
// };

export default {
	namespaced: true,
	getters,
  actions: {
    updateSessionInfo( { commit }: { commit: Commit }, session_info: SessionInfo): void {
			commit('UPDATE_SESSION_INFO',session_info);
		},
		setCourseName( { commit }: { commit: Commit }, _course_name: string): void {
			console.log(_course_name);
			commit('SET_COURSE_NAME',_course_name);
		},
		logout( { commit }: {commit: Commit }): void {
			commit('UPDATE_SESSION_INFO',{ logged_in: false});
			commit('SET_COURSE_NAME','');
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
		SET_COURSE_NAME(state: SessionState, _course_name: string): void {
			state.course_name = _course_name;
		}
	},
	state
};

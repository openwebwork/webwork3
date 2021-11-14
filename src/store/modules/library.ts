// import { api } from 'boot/axios';
import axios from 'axios';
import { Commit } from 'vuex';

import { Discipline, LibrarySubject } from '@/store/models/library';
import { LibraryProblem, parseProblem } from '@/store/models/set_problem';

export interface LibraryState {
	disciplines: Array<Discipline>;
	subjects: Array<LibrarySubject>;
	chapters: Array<LibrarySubject>;
	sections: Array<LibrarySubject>;
	problems: Array<LibraryProblem>;
}

const initial_state = {
	disciplines: [],
	subjects: [],
	chapters: [],
	sections: [],
	problems: [],
};

interface LibraryID {
	disc_id: number;
	subj_id?: number;
	chap_id?: number;
	sect_id?: number;
}

export default {
	namespaced: true,
	state: initial_state,
	getters: {
		problems(state: LibraryState): Array<LibraryProblem> {
			return state.problems;
		}
	},
	actions: {
		async fetchDisciplines({ commit }: { commit: Commit }): Promise<void> {
			const response = await axios.get('/opl/api/taxo/disciplines');
			commit('SET_DISCIPLINES', response.data as Array<Discipline>);
		},
		resetSubjects({ commit }: { commit: Commit }): void {
			commit('SET_SUBJECTS', []);
		},
		async fetchSubjects({ commit }: { commit: Commit }, lib_id: LibraryID): Promise<void> {
			const response = await axios.get(`/opl/api/taxo/disciplines/${lib_id.disc_id}/subjects`);
			commit('SET_SUBJECTS', response.data as Array<LibrarySubject>);
		},
		resetChapters({ commit }: { commit: Commit }): void {
			commit('SET_CHAPTERS', []);
		},
		async fetchChapters({ commit }: { commit: Commit }, lib_id: LibraryID): Promise<void> {
			const url = `/opl/api/taxo/disciplines/${lib_id.disc_id}/subjects/${lib_id.subj_id ?? 0}/chapters`;
			const response = await axios.get(url);
			commit('SET_CHAPTERS', response.data as Array<LibrarySubject>);
		},
		resetSections({ commit }: { commit: Commit }): void {
			commit('SET_SECTIONS', []);
		},
		async fetchSections({ commit }: { commit: Commit }, lib_id: LibraryID): Promise<void> {
			const url = `${lib_id.disc_id}/subjects/${lib_id.subj_id ?? 0}/chapters/${lib_id.chap_id ?? 0}`;
			const response = await axios.get(`/opl/api/taxo/disciplines/${url}/sections`);
			commit('SET_SECTIONS', response.data as Array<LibrarySubject>);
		},
		resetProblems({ commit }: { commit: Commit }): void {
			commit('SET_PROBLEMS', []);
		},
		async fetchLibraryProblems({ commit }: { commit: Commit }, lib_id: LibraryID): Promise<void> {
			const response = await axios.get(`/opl/api/problems/sections/${lib_id.sect_id || 0}`);
			const _problems_to_parse = response.data as Array<{ id: number; file_path: string }>;

			commit('SET_PROBLEMS', _problems_to_parse.map(p => parseProblem({ problem_params:
					{ library_id: p.id, file_path: p.file_path } }, 'Library')));
		}
	},
	mutations: {
		SET_DISCIPLINES(state: LibraryState, _disciplines: Array<Discipline>): void {
			state.disciplines = _disciplines;
		},
		SET_SUBJECTS(state: LibraryState, _subjects: Array<LibrarySubject>): void {
			state.subjects = _subjects;
		},
		SET_CHAPTERS(state: LibraryState, _chapters: Array<LibrarySubject>): void {
			state.chapters = _chapters;
		},
		SET_SECTIONS(state: LibraryState, _sections: Array<LibrarySubject>): void {
			state.sections = _sections;
		},
		SET_PROBLEMS(state: LibraryState, _problems: Array<LibraryProblem>): void {
			state.problems = _problems;
		}
	}
};

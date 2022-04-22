import axios from 'axios';

import { LibraryProblem, parseProblem } from 'src/common/models/problems';

interface LibraryID {
	disc_id: number;
	subj_id?: number;
	chap_id?: number;
	sect_id?: number;
}

export interface LibraryCategory {
	id: number;
	name: string;
	official: boolean;
	crossref?: number;
}

export const fetchDisciplines = async ()  => {
	const response = await axios.get('/opl/api/taxo/disciplines');
	return response.data as Array<LibraryCategory>;
};

export const fetchSubjects = async (lib_id: LibraryID) => {
	const response = await axios.get(`/opl/api/taxo/disciplines/${lib_id.disc_id}/subjects`);
	return response.data as Array<LibraryCategory>;
};

export const fetchChapters = async (lib_id: LibraryID) => {
	const response = await axios.get(`/opl/api/taxo/disciplines/${
		lib_id.disc_id}/subjects/${lib_id.subj_id ?? 0}/chapters`);
	return response.data as Array<LibraryCategory>;
};

export const fetchSections = async (lib_id: LibraryID) => {
	const response = await axios.get(`/opl/api/taxo/disciplines/${lib_id.disc_id}/subjects/${
		lib_id.subj_id ?? 0}/chapters/${lib_id.chap_id ?? 0}/sections`);
	return response.data as Array<LibraryCategory>;
};

export const fetchLibraryProblems = async(lib_id: LibraryID) => {
	const response = await axios.get(`/opl/api/problems/sections/${lib_id.sect_id || 0}`);
	const _problems_to_parse = response.data as Array<{ id: number; file_path: string }>;
	return _problems_to_parse.map(p => parseProblem({
		location_params: {
			library_id: p.id,
			file_path: p.file_path,
			problem_pool_id: 0
		}
	}, 'Library')) as Array<LibraryProblem>;
};

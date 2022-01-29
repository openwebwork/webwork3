import axios from 'axios';

import { LibraryProblem } from 'src/common/models/problems';

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
	const url = `/opl/api/taxo/disciplines/${lib_id.disc_id}/subjects/${lib_id.subj_id ?? 0}/chapters`;
	const response = await axios.get(url);
	return response.data as Array<LibraryCategory>;
};

export const fetchSections = async (lib_id: LibraryID) => {
	const url = `${lib_id.disc_id}/subjects/${lib_id.subj_id ?? 0}/chapters/${lib_id.chap_id ?? 0}`;
	const response = await axios.get(`/opl/api/taxo/disciplines/${url}/sections`);
	return response.data as Array<LibraryCategory>;
};

export const fetchLibraryProblems = async(lib_id: LibraryID) => {
	const response = await axios.get(`/opl/api/problems/sections/${lib_id.sect_id || 0}`);
	const _problems_to_parse = response.data as Array<{ id: number; file_path: string }>;
	return _problems_to_parse.map(p => new LibraryProblem({ location_params: { file_path: p.file_path } }));
};

/* This file contains common functions and constants needs for general use */

import { date } from 'quasar';

export function formatDate(_date_to_format: string) {
	const _date = new Date();
	_date.setTime(parseInt(_date_to_format) * 1000); //js dates have milliseconds instead of standard unix epoch
	return date.formatDate(_date, 'MM-DD-YYYY [at] h:mmA'); // have the format changeable?
}

export interface ViewInfo {
	name: string;
	component_name: string;
	icon: string;
	route: string;
	sidebars: Array<string>;
}

export const student_views = [
	{
		name: 'Calendar',
		componentName: 'Calendar',
		icon: 'today',
		route: 'student-calendar',
		sidebars: []
	},
	{
		name: 'Problem Viewer',
		componentName: 'ProblemViewer',
		icon: 'preview',
		route: 'student-problems',
		sidebars: []
	}
];

export const instructor_views = [
	{
		name: 'Calendar',
		component_name: 'Calendar',
		icon: 'today',
		route: 'calendar',
		sidebars: ['problem_sets']
	},
	{
		name: 'Problem Viewer',
		component_name: 'ProblemViewer',
		icon: 'preview',
		route: 'viewer',
		sidebars: []
	},
	{
		name: 'Classlist Manager',
		component_name: 'ClasslistManager',
		icon: 'people',
		route: 'classlist',
		sidebars: []
	},
	{
		name: 'Problem Set Details',
		component_name: 'SetDetailContainer',
		icon: 'info',
		route: 'set-view',
		sidebars: ['problem_sets']
	},
	{
		name: 'Library Browser',
		component_name: 'LibraryBrowser',
		icon: 'book',
		route: 'library',
		sidebars: ['library']
	},
	{
		name: 'Problem Sets Manager',
		component_name: 'ProblemSetsManager',
		icon: 'list',
		route: 'problem-sets',
		sidebars: ['problem_sets']
	},
	{
		name: 'Problem Editor',
		component_name: 'ProblemEditor',
		icon: 'edit ',
		route: 'editor',
		sidebars: []
	},
	{
		name: 'Statistics',
		component_name: 'Statistics',
		icon: 'assessment',
		route: 'statistics',
		sidebars: []
	},
	{
		name: 'Settings',
		component_name: 'Settings',
		icon: 'settings',
		route: 'settings',
		sidebars: []
	}
];

export const admin_views = [
	{
		name: 'Course Manager',
		component_name: 'CourseManager',
		icon: 'assessment',
		route: 'coursemanager',
		sidebars: []
	}
];

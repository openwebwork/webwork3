/* This file contains common functions and constants needs for general use */

export interface MenuBarView {
	name: string;
	component_name: string;
	icon: string;
	route: string;
	show_set: boolean;
	show_user: boolean;
}

export const student_views = [
	{
		name: 'Calendar',
		componentName: 'Calendar',
		icon: 'today',
		route: 'student-calendar',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Problem Viewer',
		componentName: 'ProblemViewer',
		icon: 'preview',
		route: 'student-problems',
		show_set: false,
		show_user: false,
	},
];

export const instructor_views = [
	{
		name: 'Calendar',
		component_name: 'Calendar',
		icon: 'today',
		route: 'calendar',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Problem Viewer',
		component_name: 'ProblemViewer',
		icon: 'preview',
		route: 'viewer',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Classlist Manager',
		component_name: 'ClasslistManager',
		icon: 'people',
		route: 'classlist',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Problem Set Details',
		component_name: 'ProblemSetDetails',
		icon: 'info',
		route: 'set-view',
		show_set: true,
		show_user: false,
	},
	{
		name: 'Library Browser',
		component_name: 'LibraryBrowser',
		icon: 'book',
		route: 'library',
		show_set: true,
		show_user: false,
	},
	{
		name: 'Problem Sets Manager',
		component_name: 'ProblemSetsManager',
		icon: 'list',
		route: 'problem-sets',
		show_set: false,
		show_user: true,
	},
	{
		name: 'Problem Editor',
		component_name: 'ProblemEditor',
		icon: 'edit ',
		route: 'editor',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Statistics',
		component_name: 'Stastistics',
		icon: 'assessment',
		route: 'statistics',
		show_set: false,
		show_user: false,
	},
	{
		name: 'Settings',
		component_name: 'Settings',
		icon: 'settings',
		route: 'settings',
		show_set: false,
		show_user: false,
	},
];
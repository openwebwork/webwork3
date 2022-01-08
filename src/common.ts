/* This file contains common functions and constants needs for general use */

import { date } from 'quasar';
import type { HomeworkSetDates, ReviewSetDates, QuizDates } from 'src/store/models/problem_sets';

export function formatDate(_date_to_format: string | number) {
	const _date = new Date();
	_date.setTime(parseInt(`${_date_to_format}`) * 1000); //js dates have milliseconds instead of standard unix epoch
	return date.formatDate(_date, 'MM-DD-YYYY [at] h:mmA'); // have the format changeable?
}

export const checkHWDates = (dates: HomeworkSetDates, enable_reduced_scoring?: boolean): boolean | string =>
	enable_reduced_scoring && dates.reduced_scoring ?
		(dates.open <= dates.reduced_scoring && dates.reduced_scoring <= dates.due  && dates.due <= dates.answer) :
		(dates.open <= dates.due && dates.due <= dates.answer) ||
		'The dates must be in order';

export const checkQuizDates = (dates: QuizDates): boolean | string =>
	dates.open <= dates.due && dates.due <= dates.answer ||
		'The dates must be in order';

export const checkReviewSetDates = (dates: ReviewSetDates): boolean | string => dates.open <= dates.closed ||
		'The dates must be in order';

export interface ViewInfo {
	name: string;
	component_name: string;
	icon: string;
	route: string;
	sidebars: Array<string>;
	children?: Array<string>;
}

export const student_views: Array<ViewInfo> = [
	{
		name: 'Dashboard',
		component_name: 'StudentDashboard',
		icon: 'speed',
		route: '',
		sidebars: []
	},
	{
		name: 'Calendar',
		component_name: 'StudentCalendar',
		icon: 'today',
		route: 'calendar',
		sidebars: []
	},
	{
		name: 'Problem Viewer',
		component_name: 'StudentProblemViewer',
		icon: 'preview',
		route: 'problems',
		sidebars: []
	},
	{
		name: 'Grades',
		component_name: 'Grades',
		icon: 'list',
		route: 'grades',
		sidebars: []
	}
];

export const instructor_views: Array<ViewInfo> = [
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
		sidebars: ['problem_sets'],
		children: ['ProblemSetDetails']
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

export const admin_views: Array<ViewInfo> = [
	{
		name: 'Course Manager',
		component_name: 'CourseManager',
		icon: 'assessment',
		route: 'coursemanager',
		sidebars: []
	}
];

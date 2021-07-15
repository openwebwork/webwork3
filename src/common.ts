/* This file contains common functions and constants needs for general use */

export interface MenuBarView {
  name: string;
  icon: string;
  route: string;
  show_set: boolean;
  show_user: boolean;
}

export const student_views = [
  {
    name: 'Calendar',
    icon: 'today',
    route: 'student-calendar',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Problem Viewer',
    icon: 'eye',
    route: 'student-problems',
    show_set: false,
    show_user: false,
  },
];

export const instructor_views = [
  {
    name: 'Calendar',
    icon: 'today',
    route: 'calendar',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Problem Viewer',
    icon: 'panorama',
    route: 'viewer',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Classlist Manager',
    icon: 'people',
    route: 'classlist',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Problem Set Details',
    icon: 'info-square',
    route: 'set-view',
    show_set: true,
    show_user: false,
  },
  {
    name: 'Library Browser',
    icon: 'book',
    route: 'library',
    show_set: true,
    show_user: false,
  },
  {
    name: 'Problem Sets Manager',
    icon: 'list-ul',
    route: 'problem-sets',
    show_set: false,
    show_user: true,
  },
  {
    name: 'Problem Editor',
    icon: 'edit ',
    route: 'editor',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Statistics',
    icon: 'assessment',
    route: 'statistics',
    show_set: false,
    show_user: false,
  },
  {
    name: 'Settings',
    icon: 'settings',
    route: 'settings',
    show_set: false,
    show_user: false,
  },
];
import { RouteRecordRaw } from 'vue-router';

import Login from '../components/common/Login.vue';
import Welcome from '../components/common/Welcome.vue';
import MainLayout from '../layouts/MainLayout.vue';
// import Empty from '../components/common/Empty.vue';

import UserCourses from '../components/common/UserCourses.vue';
import Instructor from '../components/instructor/Instructor.vue';
import Student from '../components/student/Student.vue';
import Settings from '../components/instructor/Settings.vue';
import Calendar from '../components/instructor/Calendar.vue';
import ProblemViewer from '../components/common/ProblemViewer.vue';
import ClasslistManager from '../components/instructor/ClasslistManager.vue';
import ProblemSetDetails from '../components/instructor/ProblemSetDetails.vue';
import LibraryBrowser from '../components/instructor/LibraryBrowser.vue';
import ProblemSetsManager from '../components/instructor/ProblemSetsManager.vue';
import ProblemEditor from '../components/instructor/ProblemEditor.vue';


// Admin components
import Admin from '../components/admin/Admin.vue';
import AdminCourses from '../components/admin/AdminCourses.vue';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/webwork3/login'
	},
	{
		path: '/webwork3',
		component: MainLayout,
		children: [
			{
				path: 'welcome',
				component: Welcome,
				name: 'welcome'
			},
			{
				path: 'login',
				component: Login
			},
			{
				path: 'users/:user_id/courses',
				component: UserCourses
			},
			{
				path: 'courses/:course_id',
				component: Student,
				name: 'student',
				props: true,
				meta: { requiresAuth: true },
			},
			{
				path: 'courses/:course_id/instructor',
				component: Instructor,
				name: 'instructor',
				props: true,
				meta: {requiresAuth: true},
				// beforeEnter: (to, from) => {
				// 	console.log(to);
				// 	console.log(from);
				// },
				children:
				[
					{
						path: 'settings',
						name: 'Settings',
						component: Settings
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: Calendar
					},
					{
						path: 'viewer',
						name: 'ProblemViewer',
						component: ProblemViewer
					},
					{
						path: 'classlist',
						name: 'ClasslistManager',
						component: ClasslistManager,
					},
					{
						path: 'setdetails',
						name: 'ProblemSetDetails',
						component: ProblemSetDetails,
					},

					{
						path: 'library',
						name: 'LibraryBrowser',
						component: LibraryBrowser,
					},

					{
						path: 'problemsets',
						name: 'ProblemSetsManager',
						component: ProblemSetsManager,
					},

					{
						path: 'editor',
						name: 'ProblemEditor',
						component: ProblemEditor,
					}
				]
			},
			{
				path: 'admin',
				component: Admin,
				children: [
					{
						path: 'courses',
						component: AdminCourses,
						name: 'AdminCourses'
					}
				]
			},
		]
	},
	{
    path: '/:catchAll(.*)*',
    component: () => import('pages/Error404.vue'),
  },
];

export default routes;

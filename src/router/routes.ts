import { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/login'
	},
	{
		path: '/',
		component: () => import('src/layouts/MainLayout.vue'),
		children: [
			{
				path: 'welcome',
				component: () => import(/* webpackChunkName: "Welcome" */
					'src/components/common/Welcome.vue'),
				name: 'welcome'
			},
			{
				path: 'login',
				component: () => import(/* webpackChunkName: "Login" */
					'src/components/common/Login.vue')
			},
			{
				path: 'users/:user_id/courses',
				component: () => import(/* webpackChunkName: "UserCourses" */
					'src/components/common/UserCourses.vue')
			},
			{
				path: 'courses/:course_id',
				component: () => import(/* webpackChunkName: "Student" */
					'src/components/student/Student.vue'),
				name: 'student',
				props: true,
				meta: { requiresAuth: true }
			},
			{
				path: 'courses/:course_id/instructor',
				component: () => import(
					/* webpackChunkName: "Instructor" */
					'src/components/instructor/Instructor.vue'
				),
				name: 'instructor',
				props: true,
				meta: { requiresAuth: true },
				children:
				[
					{
						path: 'settings',
						name: 'Settings',
						component: () => import(/* webpackChunkName: "Settings" */
							'src/components/instructor/Settings.vue')
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: () => import(/* webpackChunkName: "Calendar" */
							'src/components/instructor/Calendar.vue')
					},
					{
						path: 'viewer',
						name: 'ProblemViewer',
						component: () => import(/* webpackChunkName: "ProblemViewer" */
							'src/components/common/ProblemViewer.vue')
					},
					{
						path: 'classlist',
						name: 'ClasslistManager',
						component: () => import(
							/* webpackChunkName: "ClasslistManager" */
							'src/components/instructor/ClasslistManager.vue'
						)
					},
					{
						path: 'setdetails',
						name: 'ProblemSetDetails',
						component: () => import(/* webpackChunkName: "ProblemSetDetails" */
							'src/components/instructor/ProblemSetDetails.vue')
					},

					{
						path: 'library',
						name: 'LibraryBrowser',
						component: () => import(/* webpackChunkName: "LibraryBrowser" */
							'src/components/instructor/LibraryBrowser.vue')
					},

					{
						path: 'problemsets',
						name: 'ProblemSetsManager',
						component: () => import(/* webpackChunkName: "ProblemSetsManager" */
							'src/components/instructor/ProblemSetsManager.vue')
					},

					{
						path: 'editor',
						name: 'ProblemEditor',
						component: () => import(/* webpackChunkName: "ProblemEditor" */
							'src/components/instructor/ProblemEditor.vue')
					}
				]
			}
		]
	},
	{
		path: '/:catchAll(.*)*',
		component: () => import('pages/Error404.vue')
	}
];

export default routes;

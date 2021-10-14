import { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/login'
	},
	{
		path: '/',
		component: () => import(/* webpackChunkName: "MainLayout" */ '@/layouts/MainLayout.vue'),
		children: [
			{
				path: 'welcome',
				component: () =>
					import(
						/* webpackChunkName: "Welcome" */
						'@/components/common/Welcome.vue'
					),
				name: 'welcome'
			},
			{
				path: 'login',
				component: () =>
					import(
						/* webpackChunkName: "Login" */
						'@/components/common/Login.vue'
					)
			},
			{
				path: 'users/:user_id/courses',
				component: () =>
					import(
						/* webpackChunkName: "UserCourses" */
						'@/components/common/UserCourses.vue'
					)
			},
			{
				path: 'courses/:course_id',
				component: () =>
					import(
						/* webpackChunkName: "Student" */
						'@/components/student/Student.vue'
					),
				name: 'student',
				props: true,
				meta: { requiresAuth: true }
			},
			{
				path: 'courses/:course_id/instructor',
				component: () =>
					import(
						/* webpackChunkName: "Instructor" */
						'@/components/instructor/Instructor.vue'
					),
				name: 'instructor',
				props: true,
				meta: { requiresAuth: true },
				children: [
					{
						path: 'settings',
						name: 'Settings',
						component: () =>
							import(
								/* webpackChunkName: "Settings" */
								'@/components/instructor/Settings.vue'
							)
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: () =>
							import(
								/* webpackChunkName: "Calendar" */
								'@/components/instructor/Calendar.vue'
							)
					},
					{
						path: 'viewer',
						name: 'ProblemViewer',
						component: () =>
							import(
								/* webpackChunkName: "ProblemViewer" */
								'@/components/common/ProblemViewer.vue'
							)
					},
					{
						path: 'classlist',
						name: 'ClasslistManager',
						component: () =>
							import(
								/* webpackChunkName: "ClasslistManager" */
								'@/components/instructor/ClasslistManager.vue'
							)
					},
					{
						path: 'sets',
						name: 'SetDetailContainer',
						component: () =>
							import(
								/* webpackChunkName: "SetDetailContainer" */
								'@/components/instructor/SetDetails/SetDetailContainer.vue'
							),
						children: [
							{
								path: ':set_id',
								name: 'ProblemSetDetails',
								component: () =>
									import(
										/* webpackChunkName: "ProblemSetDetails" */
										'@/components/instructor/SetDetails/ProblemSetDetails.vue'
									)
							}
						]
					},

					{
						path: 'library',
						name: 'LibraryBrowser',
						component: () =>
							import(
								/* webpackChunkName: "LibraryBrowser" */
								'@/components/instructor/LibraryBrowser.vue'
							)
					},

					{
						path: 'setmanager',
						name: 'ProblemSetsManager',
						component: () =>
							import(
								/* webpackChunkName: "ProblemSetsManager" */
								'@/components/instructor/ProblemSetsManager.vue'
							)
					},

					{
						path: 'editor',
						name: 'ProblemEditor',
						component: () =>
							import(
								/* webpackChunkName: "ProblemEditor" */
								'@/components/instructor/ProblemEditor.vue'
							)
					},

					{
						path: 'statistics',
						name: 'Statistics',
						component: () =>
							import(
								/* webpackChunkName: "Statistics" */
								'@/components/instructor/Statistics.vue'
							)
					}
				]
			},
			{
				path: 'admin',
				component: () =>
					import(
						/* webpackChunkName: "Admin" */
						'@/components/admin/Admin.vue'
					),
				children: [
					{
						path: 'courses',
						component: () =>
							import(
								/* webpackChunkName: "CourseMananger" */
								'@/components/admin/CourseManager.vue'
							),
						name: 'CourseManager'
					}
				]
			}
		]
	},
	{
		path: '/:catchAll(.*)*',
		component: () => import(/* webpackChunkName: "Error404" */ 'pages/Error404.vue')
	}
];

export default routes;

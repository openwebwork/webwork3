import { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/login'
	},
	{
		path: '/',
		component: () => import(/* webpackChunkName: "MainLayout" */ 'src/layouts/MainLayout.vue'),
		children: [
			{
				path: 'welcome',
				component: () =>
					import(
						/* webpackChunkName: "Welcome" */
						'src/components/common/Welcome.vue'
					),
				name: 'welcome'
			},
			{
				path: 'login',
				component: () =>
					import(
						/* webpackChunkName: "Login" */
						'src/components/common/Login.vue'
					)
			},
			{
				path: 'users/:user_id/courses',
				component: () =>
					import(
						/* webpackChunkName: "UserCourses" */
						'src/components/common/UserCourses.vue'
					)
			},
			{
				path: 'courses/:course_id',
				component: () =>
					import(
						/* webpackChunkName: "Student" */
						'src/components/student/Student.vue'
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
						'src/components/instructor/Instructor.vue'
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
								'src/components/instructor/Settings.vue'
							)
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: () =>
							import(
								/* webpackChunkName: "Calendar" */
								'src/components/instructor/Calendar.vue'
							)
					},
					{
						path: 'viewer',
						name: 'ProblemViewer',
						component: () =>
							import(
								/* webpackChunkName: "ProblemViewer" */
								'src/components/common/ProblemViewer.vue'
							)
					},
					{
						path: 'classlist',
						name: 'ClasslistManager',
						component: () =>
							import(
								/* webpackChunkName: "ClasslistManager" */
								'src/components/instructor/ClasslistManager.vue'
							)
					},
					{
						path: 'sets',
						name: 'SetDetailContainer',
						component: () =>
							import(
								/* webpackChunkName: "SetDetailContainer" */
								'src/components/instructor/SetDetails/SetDetailContainer.vue'
							),
						children: [
							{
								path: ':set_id',
								name: 'ProblemSetDetails',
								component: () =>
									import(
										/* webpackChunkName: "ProblemSetDetails" */
										'src/components/instructor/SetDetails/ProblemSetDetails.vue'
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
								'src/components/instructor/LibraryBrowser.vue'
							)
					},

					{
						path: 'setmanager',
						name: 'ProblemSetsManager',
						component: () =>
							import(
								/* webpackChunkName: "ProblemSetsManager" */
								'src/components/instructor/ProblemSetsManager.vue'
							)
					},

					{
						path: 'editor',
						name: 'ProblemEditor',
						component: () =>
							import(
								/* webpackChunkName: "ProblemEditor" */
								'src/components/instructor/ProblemEditor.vue'
							)
					},

					{
						path: 'statistics',
						name: 'Statistics',
						component: () =>
							import(
								/* webpackChunkName: "Statistics" */
								'src/components/instructor/Statistics.vue'
							)
					}
				]
			},
			{
				path: 'admin',
				component: () =>
					import(
						/* webpackChunkName: "Admin" */
						'src/components/admin/Admin.vue'
					),
				children: [
					{
						path: 'courses',
						component: () =>
							import(
								/* webpackChunkName: "CourseMananger" */
								'src/components/admin/CourseManager.vue'
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

import { RouteRecordRaw } from 'vue-router';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/login'
	},
	{
		path: '/',
		component: () => import(/* webpackChunkName: "MainLayout" */ 'layouts/MainLayout.vue'),
		children: [
			{
				path: 'welcome',
				component: () =>
					import(
						/* webpackChunkName: "Welcome" */
						'components/common/Welcome.vue'
					),
				name: 'welcome'
			},
			{
				path: 'login',
				component: () =>
					import(
						/* webpackChunkName: "Login" */
						'components/common/Login.vue'
					)
			},
			{
				path: 'users/:user_id/courses',
				component: () =>
					import(
						/* webpackChunkName: "UserCourses" */
						'components/common/UserCourses.vue'
					)
			},
			{
				path: 'courses/:course_id',
				component: () =>
					import(
						/* webpackChunkName: "Student" */
						'components/student/Student.vue'
					),
				name: 'student',
				props: true,
				meta: { requiresAuth: true },
				children: [
					{
						path: '',
						name: 'StudentDashboard',
						component: () =>
							import(
								/* webpackChunkName: "StudentDashboard" */
								'pages/student/Dashboard.vue'
							)
					},
					{
						path: 'calendar',
						name: 'StudentCalendar',
						component: () =>
							import(
								/* webpackChunkName: "StudentCalendar" */
								'pages/student/Calendar.vue'
							)
					},
					{
						path: 'sets',
						name: 'ProblemSetsContainer',
						component: () =>
							import(
								/* webpackChunkName: "ProblemSetsContainer" */
								'src/pages/student/ProblemSetsContainer.vue'
							),
						children: [
							{
								path: ':set_id',
								name: 'ProblemSets',
								component: () =>
									import(
										/* webpackChunkName: "ProblemSets" */
										'src/pages/student/ProblemSets.vue'
									)
							}
						]
					},
					{
						path: 'grades',
						name: 'Grades',
						component: () =>
							import(
								/* webpackChunkName: "Grades" */
								'pages/student/Grades.vue'
							)
					},
				]
			},
			{
				path: 'courses/:course_id/instructor',
				component: () =>
					import(
						/* webpackChunkName: "Instructor" */
						'pages/instructor/Instructor.vue'
					),
				name: 'instructor',
				meta: { requiresAuth: true },
				children: [
					{
						path: 'settings',
						name: 'Settings',
						component: () =>
							import(
								/* webpackChunkName: "Settings" */
								'pages/instructor/Settings.vue'
							)
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: () =>
							import(
								/* webpackChunkName: "Calendar" */
								'pages/instructor/Calendar.vue'
							)
					},
					{
						path: 'viewer',
						name: 'ProblemViewer',
						component: () =>
							import(
								/* webpackChunkName: "ProblemViewer" */
								'components/common/ProblemViewer.vue'
							)
					},
					{
						path: 'classlist',
						name: 'ClasslistManager',
						component: () =>
							import(
								/* webpackChunkName: "ClasslistManager" */
								'pages/instructor/ClasslistManager.vue'
							)
					},
					{
						path: 'sets',
						name: 'SetDetailContainer',
						component: () =>
							import(
								/* webpackChunkName: "SetDetailContainer" */
								'pages/instructor/SetDetailContainer.vue'
							),
						children: [
							{
								path: ':set_id',
								name: 'ProblemSetDetails',
								component: () =>
									import(
										/* webpackChunkName: "ProblemSetDetails" */
										'pages/instructor/ProblemSetDetails.vue'
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
								'pages/instructor/LibraryBrowser.vue'
							)
					},

					{
						path: 'setmanager',
						name: 'ProblemSetsManager',
						component: () =>
							import(
								/* webpackChunkName: "ProblemSetsManager" */
								'pages/instructor/ProblemSetsManager.vue'
							)
					},

					{
						path: 'editor',
						name: 'ProblemEditor',
						component: () =>
							import(
								/* webpackChunkName: "ProblemEditor" */
								'pages/instructor/ProblemEditor.vue'
							)
					},

					{
						path: 'statistics',
						name: 'Statistics',
						component: () =>
							import(
								/* webpackChunkName: "Statistics" */
								'pages/instructor/Statistics.vue'
							)
					}
				]
			},
			{
				path: 'admin',
				component: () =>
					import(
						/* webpackChunkName: "Admin" */
						'components/admin/Admin.vue'
					),
				children: [
					{
						path: 'courses',
						component: () =>
							import(
								/* webpackChunkName: "CourseMananger" */
								'components/admin/CourseManager.vue'
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

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
						'components/common/WelcomeVue.vue'
					),
				name: 'welcome'
			},
			{
				path: 'login',
				name: 'login',
				component: () =>
					import(
						/* webpackChunkName: "Login" */
						'components/common/LoginVue.vue'
					)
			},
			{
				path: 'users/:user_id/courses',
				name: 'user_courses',
				component: () =>
					import(
						/* webpackChunkName: "UserCourses" */
						'components/common/UserCourses.vue'
					)
			},
			{
				path: 'courses/:course_id/student',
				component: () =>
					import(
						/* webpackChunkName: "Student" */
						'components/student/StudentVue.vue'
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
								'pages/student/StudentDashboard.vue'
							)
					},
					{
						path: 'calendar',
						name: 'StudentCalendar',
						component: () =>
							import(
								/* webpackChunkName: "StudentCalendar" */
								'pages/student/StudentCalendar.vue'
							)
					},
					{
						path: 'sets',
						name: 'ProblemSets',
						component: () =>
							import(
								/* webpackChunkName: "ProblemSets" */
								'pages/student/ProblemSets.vue'
							)
					},
					{
						path: 'sets/:set_id',
						name: 'StudentProblemContainer',
						component: () =>
							import(
								/* webpackChunkName: "StudentProblemContainer" */
								'src/pages/student/StudentProblemContainer.vue'
							),
						children: [
							{
								path: 'problems/:problem_id',
								name: 'StudentProblem',
								component: () =>
									import(
										/* webpackChunkName: "StudentProblem" */
										'src/pages/student/StudentProblem.vue'
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
								'pages/student/StudentGrades.vue'
							)
					},
				]
			},
			{
				path: 'courses/:course_id/instructor',
				component: () =>
					import(
						/* webpackChunkName: "Instructor" */
						'pages/instructor/InstructorVue.vue'
					),
				name: 'instructor',
				meta: { requiresAuth: true },
				children: [
					{
						path: '',
						name: 'InstructorDashboard',
						component: () =>
							import(
								/* webpackChunkName: "Dashboard" */
								'pages/instructor/InstructorDashboard.vue'
							)
					},
					{
						path: 'settings',
						name: 'Settings',
						component: () =>
							import(
								/* webpackChunkName: "Settings" */
								'pages/instructor/SettingsVue.vue'
							)
					},
					{
						path: 'calendar',
						name: 'Calendar',
						component: () =>
							import(
								/* webpackChunkName: "Calendar" */
								'pages/instructor/InstructorCalendar.vue'
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
								'pages/instructor/StatisticsVue.vue'
							)
					}
				]
			},
			{
				path: 'admin',
				component: () =>
					import(
						/* webpackChunkName: "Admin" */
						'components/admin/AdminVue.vue'
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

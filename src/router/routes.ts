import { RouteRecordRaw } from 'vue-router';

import Login from '../components/common/Login.vue';
import Welcome from '../components/common/Welcome.vue';
// import Empty from '../components/common/Empty.vue';
import UserCourses from '../components/common/UserCourses.vue';
import Instructor from '../components/instructor/Instructor.vue';
import Student from '../components/student/Student.vue';

const routes: RouteRecordRaw[] = [
	{
		path: '/',
		redirect: '/webwork3/login'
	},
	{
		path: '/webwork3',
		component: () => import('layouts/MainLayout.vue'),
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
				beforeEnter: (to, from) => {
					console.log(to);
					console.log(from);
				}
			},
		]
	},
	{
    path: '/:catchAll(.*)*',
    component: () => import('pages/Error404.vue'),
  },
];

export default routes;

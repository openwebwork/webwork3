import Login from "@/components/common/Login.vue";
import Welcome from "@/components/common/Welcome.vue";
import Empty from "@/components/common/Empty.vue";
import UserCourses from "@/components/common/UserCourses.vue";
import Student from "@/components/student/Student.vue";
import Instructor from "@/components/instructor/Instructor.vue";

import { createRouter, createWebHistory } from 'vue-router';

const routes = [
	{
		path: "/",
		redirect: "/webwork3/login"
	},
	{
		path: "/webwork3",
		component: Empty,
		children: [
				{
					path: "welcome",
					component: Welcome,
					name: 'welcome'
				},
				{
					path: "login",
					component: Login
				},
				{
					path: "users/:user_id/courses",
					component: UserCourses
				},
				{
					path: "courses/:course_id",
					component: Student,
					name: 'student',
					props: true,
					meta: {requiresAuth: true}
				},
				{
					path: "courses/:course_id/instructor",
					component: Instructor,
					name: 'instructor',
					props: true,
					meta: {requiresAuth: true}
				},
			]
		}
	];


const router = createRouter({
  // 4. Provide the history implementation to use. We are using the hash history for simplicity here.
  history: createWebHistory(),
  routes, // short for `routes: routes`
});

export default router;


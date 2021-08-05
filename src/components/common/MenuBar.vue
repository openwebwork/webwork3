<template>
	<q-header>
		<q-toolbar>
			<q-toolbar-title>
				WeBWorK
				<q-btn-dropdown color="primary" :label="current_view" menu-anchor="bottom middle" no-caps>
				<template v-for="view in views" :key="view">
					<q-item clickable v-close-popup @click="changeView(view)" :icon="view.icon">
						<q-item-section avatar>
							<q-icon :name="view.icon" />
						</q-item-section>
						<q-item-section>{{view.name}}</q-item-section>
					</q-item>
				</template>
			</q-btn-dropdown>

			</q-toolbar-title>
			<q-space />
			<q-btn-dropdown v-if="logged_in" color="purple" icon="person" :label="full_name">
			<q-list>
				<q-item clickable v-close-popup @click="logout">Logout</q-item>
			</q-list>
		</q-btn-dropdown>
		<q-btn v-else><router-link to="/webwork3/login">Login</router-link></q-btn>
			<q-btn-dropdown color="purple" :label="course_name" v-if="course_name !== ''">
			<q-list>
				<template v-for="course in user_courses" :key="course.course_id">
					<q-item clickable v-close-popup @click="changeCourse(course.course_id,course.course_name)">
						<q-item-section>
							<q-item-label>{{course.course_name}}</q-item-label>
						</q-item-section>
					</q-item>
				</template>
			</q-list>
		</q-btn-dropdown>
		</q-toolbar>
	</q-header>
</template>


<script lang="ts">
import { computed, defineComponent, ref } from 'vue';
import { useStore } from '../../store';
import { useRouter, useRoute } from 'vue-router';

import { instructor_views, MenuBarView } from '../../common';

import { UserCourse } from '../../store/models';

export default defineComponent({
	name: 'MenuBar',
	setup() {
		const store = useStore();
		const router = useRouter();
		const route = useRoute();
		const current_view = ref('');

		return {

			logged_in: computed( () => store.state.session.logged_in),
			user: computed( () => store.state.session.user),

			full_name: computed( () => `${store.state.session.user.first_name} ${store.state.session.user.last_name}`),
			course_name: computed( () => store.state.session.course.course_name),
			user_courses: computed( () => {
				const current_course_name = store.state.session.course.course_name;
				return store.state.user.user_courses
					.filter( (course: UserCourse) => course.course_name !== current_course_name);
			}),
			changeCourse: (course_id: number, course_name: string) => {
				const current_course_name = store.state.session.course.course_name;
				const current_course = store.state.user.user_courses
					.filter( (course: UserCourse) => course.course_name === current_course_name)[0];

				const new_course = store.state.user.user_courses
					.filter( (course: UserCourse) => course.course_name === course_name)[0];
				if (current_course.role !== new_course.role) {
					void router.push({name: new_course.role, params: {course_id: course_id}});
				}
				void store.dispatch('session/setCourseName',course_name);
			},
			current_view,
			views: computed( () => instructor_views),
			changeView: (view: MenuBarView) => {
				current_view.value = view.name;
				void router.push({name: view.component_name, params: route.params});
			},
			logout: () => {
				void store.dispatch('session/logout');
				void router.push('/webwork3/login');
			}
		};
	},

});
</script>
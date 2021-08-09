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
					<q-item clickable>User Settings</q-item>
					<q-item clickable v-close-popup @click="logout">Logout</q-item>
				</q-list>
			</q-btn-dropdown>
			<q-btn-dropdown color="purple" :label="current_course_name" v-if="current_course_name">
				<q-list>
					<template v-for="course in user_courses" :key="course.course_id">
						<q-item clickable v-close-popup @click="changeCourse(course.course_id, course.course_name)">
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
import { useStore } from 'src/store';
import { useRouter, useRoute } from 'vue-router';
import { instructor_views, admin_views, MenuBarView } from 'src/common';
import { UserCourse } from 'src/store/models';

export default defineComponent({
	name: 'MenuBar',
	setup() {
		const store = useStore();
		const router = useRouter();
		const route = useRoute();
		const current_view = ref('');

		const current_course_name = computed(() => store.state.session.course.course_name);

		return {
			logged_in: computed(() => store.state.session.logged_in),
			user: computed(() => store.state.session.user),
			current_course_name,
			full_name: computed(() => `${store.state.session.user.first_name} ${store.state.session.user.last_name}`),
			user_courses: computed(() => {
				return store.state.users.user_courses
					.filter((course: UserCourse) => course.course_name !== current_course_name.value);
			}),
			changeCourse: (course_id: number, course_name: string) => {
				const current_course = store.state.users.user_courses
					.filter((course: UserCourse) => course.course_name === current_course_name.value)[0];

				const new_course = store.state.users.user_courses
					.filter((course: UserCourse) => course.course_name === course_name)[0];
				if (current_course.role !== new_course.role) {
					void router.push({ name: new_course.role, params: { course_id: course_id } });
				}
				void store.dispatch('session/setCourse', { course_name, course_id });
			},
			current_view,
			views: computed(() => (/^\/admin/.exec(route.path)) ? admin_views : instructor_views),
			changeView: (view: MenuBarView) => {
				current_view.value = view.name;
				void router.push({ name: view.component_name, params: route.params });
			},
			logout: () => {
				void store.dispatch('session/logout');
				void router.push('/login');
			}
		};
	}

});
</script>

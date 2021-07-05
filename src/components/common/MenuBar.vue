<template>
	<q-header>
		<q-toolbar>
			<q-toolbar-title>
				WeBWorK
			</q-toolbar-title>
			<q-space />
			<q-btn-dropdown v-if="user!==undefined" color="purple" icon="person" :label="full_name">
      <q-list>
        <q-item clickable v-close-popup @click="logout">Logout</q-item>
      </q-list>
    </q-btn-dropdown>
		<div v-else><router-link to="/webwork3/login">Login</router-link></div>
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
import { computed, defineComponent } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';

import { Course } from '@/store/models';

export default defineComponent({
	name: 'MenuBar',
	setup() {
		const store = useStore();
		const router = useRouter();
		return {
			user: computed( () => store.getters["session/user"]),
			full_name: computed( () => {
				return store.getters["session/user"].first_name + " "
					+ store.getters["session/user"].last_name}),
			course_name: computed( () => store.getters["session/course_name"]),
			user_courses: computed( () => {
				const current_course_name = store.getters["session/course_name"];
				return store.getters["user/user_courses"]
					.filter( (course: Course) => course.course_name !== current_course_name);
			}),
			changeCourse: (course_id: number, course_name: string) => {
				const current_course_name = store.getters["session/course_name"];
				const current_course = store.getters["user/user_courses"]
					.filter( (course: Course) => course.course_name === current_course_name)[0];

				const new_course = store.getters["user/user_courses"]
					.filter( (course: Course) => course.course_name === course_name)[0];
				if (current_course.role !== new_course.role) {
					router.push({name: new_course.role, params: {course_id: course_id}});
				}
				store.dispatch('session/setCourseName',course_name);
			}
		};
	}
});
</script>
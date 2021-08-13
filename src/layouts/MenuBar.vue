<template>
	<q-header>
		<div class="row">
			<div class="col col-md-3 col-12 q-my-auto" style="background-color:#1048ae">
				<q-toolbar>
					<q-btn flat @click="toggleButton" round dense icon="menu" />
					<q-toolbar-title>
						<q-img src="images/webwork_logo.svg" position="0 50%" width="190px" fit="scale-down" />
					</q-toolbar-title>
				</q-toolbar>
			</div>
			<div class="col col-md-4 col-12 q-my-auto" style="padding:4px 0">
				<q-img src="images/maa_logo.png" position="6px 50%" width="340px" fit="scale-down" :ratio="9.5" />
			</div>
			<div class="col col-md-5 col-12 q-my-auto">
				<q-toolbar>
					<q-space />
					<q-btn-dropdown v-if="logged_in" color="secondary" icon="person" :label="full_name">
						<q-list>
							<q-item clickable>User Settings</q-item>
							<q-item clickable v-close-popup @click="logout">Logout</q-item>
						</q-list>
					</q-btn-dropdown>
					<q-btn-dropdown color="secondary" :label="current_course_name" v-if="current_course_name"
						style="margin-left:6px">
						<q-list>
							<template v-for="course in user_courses" :key="course.course_id">
								<q-item clickable v-close-popup
									@click="changeCourse(course.course_id, course.course_name)">
									<q-item-section>
										<q-item-label>{{course.course_name}}</q-item-label>
									</q-item-section>
								</q-item>
							</template>
						</q-list>
					</q-btn-dropdown>
				</q-toolbar>
			</div>
		</div>
	</q-header>
</template>

<script lang="ts">
import { computed, defineComponent, ref } from 'vue';
import { useStore } from 'src/store';
import { useRouter } from 'vue-router';
import { UserCourse } from 'src/store/models';

export default defineComponent({
	name: 'MenuBar',
	emits: {
		toggle: null
	},
	setup(_, { emit }) {
		const store = useStore();
		const router = useRouter();
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
			toggleButton: () => {
				console.log('here');
				emit('toggle', 10);
			},
			current_view,
			logout: () => {
				void store.dispatch('session/logout');
				void router.push('/login');
			}
		};
	}

});
</script>

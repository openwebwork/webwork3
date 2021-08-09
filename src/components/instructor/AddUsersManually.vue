<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col">
						<q-input outlined v-model="user.login" label="Login Name" />
					</div>
					<div class="col">
						<q-input outlined v-model="user.first_name" label="First Name" />
					</div>
					<div class="col">
						<q-input outlined v-model="user.last_name" label="Last Name" />
					</div>
					<div class="col">
						<q-input outlined v-model="user.email" label="Email" />
						</div>
					<div class="col">
						<q-input outlined v-model="user.student_id" label="Student ID" />
					</div>
					<div class="col">
						<q-select outlined v-model="user.role" :options="roles" label="Role" />
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Add This User and Another One" @click="addUser" />
				<q-btn flat label="Add This User and Close" @click="addUser" />
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, computed } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from '../../store';
import { newCourseUser, newUser } from '../../store/common';

import { CourseSetting, User, CourseUser, ResponseError } from '../../store/models';
import { AxiosError } from 'axios';

export default defineComponent({
	name: 'AddUsersManually',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const user: Ref<User> = ref(newUser());
		const course_user: Ref<CourseUser> = ref(newCourseUser());
		const store = useStore();

		return {
			user,
			roles: computed(() => {
				const role_setting = store.state.settings.course_settings
					.find((_setting: CourseSetting) => _setting.var === 'roles');
				return role_setting && role_setting.value || [];
			}),
			addUser: async () => {
				try {
					const _user = await store.dispatch('users/addGlobalUser', user) as User;
					const param = { user: course_user.value };
					void await store.dispatch('users/addCourseUser', param) as unknown as CourseUser;
					$q.notify({
						message: `The user ${_user.login} was successfully added to the course.`,
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					const data = error  && error.response && (error.response.data  as ResponseError)
						|| { exception: '' };
					$q.notify({
						// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
						message: data.exception,
						color: 'red'
					});
				}
			}
		};
	}
});
</script>
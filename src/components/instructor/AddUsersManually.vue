<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col">
						<q-input outlined v-model="user.username" label="Username" @blur="checkUser" />
					</div>
					<div class="col">
						<q-input outlined v-model="user.first_name" label="First Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input outlined v-model="user.last_name" label="Last Name" :disable="user_exists"/>
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-input outlined v-model="user.email" label="Email" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="user.student_id" label="Student ID" :disable="user_exists" />
					</div>
					<div class="col">
						<q-select outlined v-model="course_user.role" :options="roles" label="Role" />
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
import type { Ref } from 'vue';
import { defineComponent, ref, computed } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from 'src/store';
import { newCourseUser, newUser } from 'src/store/utils/users';

import { CourseSetting, User, CourseUser, ResponseError } from 'src/store/models';
import { AxiosError } from 'axios';
import { assign, remove, clone } from 'lodash';

export default defineComponent({
	name: 'AddUsersManually',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const user: Ref<User> = ref(newUser());
		const course_user: Ref<CourseUser> = ref(newCourseUser());
		const user_exists: Ref<boolean> = ref(true);
		const store = useStore();

		return {
			user,
			course_user,
			user_exists,
			// see if the user exists already and fill in the known fiels
			checkUser: async () => {
				const _user = await store.dispatch('users/getUser', user.value.username) as User;
				if (_user) {
					assign(user.value, _user);
					course_user.value.user_id = user.value.user_id;
				} else {
					user_exists.value = false;
				}
			},
			roles: computed(() => { // return an array of the roles in the course
				const all_roles = store.state.settings.course_settings.find(
					(_setting: CourseSetting) => _setting.var === 'roles'
				);
				const r = clone(all_roles?.value as Array<string>);
				remove(r, (v)=> v==='admin'); // don't allow to set admin level here.
				return r;
			}),
			addUser: async () => {
				try {
					if (! user_exists.value) {
						const u = (await store.dispatch('users/addUser', user.value)) as User;
						course_user.value.user_id = u.user_id;
					}
					void await store.dispatch('users/addCourseUser', course_user.value) as unknown as CourseUser;
					$q.notify({
						message: `The user ${user.value.username} was successfully added to the course.`,
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					const data = error?.response?.data as ResponseError || { exception: '' };
					$q.notify({
						message: data.exception,
						color: 'red'
					});
				}
			}
		};
	}
});
</script>

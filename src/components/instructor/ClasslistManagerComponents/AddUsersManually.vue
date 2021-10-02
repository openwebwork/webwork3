<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col">
						<q-input outlined v-model="course_user.username" label="Username" @blur="checkUser" />
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.first_name" label="First Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.last_name" label="Last Name" :disable="user_exists"/>
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-input outlined v-model="course_user.email" label="Email" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.student_id" label="Student ID" :disable="user_exists" />
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
import { newMergedCourseUser } from 'src/store/utils/users';

import { CourseSetting, User, MergedCourseUser, ResponseError, CourseUser } from 'src/store/models';
import { AxiosError } from 'axios';
import { pick, remove, clone } from 'lodash';

export default defineComponent({
	name: 'AddUsersManually',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const course_user: Ref<MergedCourseUser> = ref(newMergedCourseUser());
		const user_exists: Ref<boolean> = ref(true);
		const store = useStore();

		return {
			course_user,
			user_exists,
			// see if the user exists already and fill in the known fiels
			checkUser: async () => {
				try {
					const _user = await store.dispatch('users/getUser', course_user.value.username) as User;
					user_exists.value = true;
					course_user.value.user_id = _user.user_id;
					course_user.value.username = _user.username;
					course_user.value.first_name = _user.first_name;
					course_user.value.last_name = _user.last_name;
					course_user.value.email = _user.email;
				} catch (err) {
					const error = err as ResponseError;
					if (error.exception === 'DB::Exception::UserNotFound') {
						user_exists.value = false;
					}
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
						const user = pick(course_user.value, ['username', 'first_name', 'last_name', 'email']);
						const u = (await store.dispatch('users/addUser', user)) as User;
						course_user.value.user_id = u.user_id;
					}
					const _course_user = pick(course_user.value, ['role', 'user_id']);
					const cu = await store.dispatch('users/addCourseUser', _course_user) as unknown as CourseUser;
					$q.notify({
						message: `The user ${course_user.value.username} was successfully added to the course.`,
						color: 'green'
					});
					course_user.value.course_user_id = cu.course_user_id;
					void store.dispatch('users/addMergedCourseUser', course_user.value);
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

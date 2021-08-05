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
					<div class="col"><q-input outlined v-model="user.student_id" label="Student ID" /></div>
					<div class="col">
						<q-select outlined v-model="user.role" :options="roles" />
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
import { useStore } from '../../store';
import { newUser } from '../../store/common';

import { CourseSetting, User } from '../../store/models';

export default defineComponent({
	name: 'AddUsersManually',
	setup() {
		const user: Ref<User> = ref(newUser());
		// const login: Ref<string> = ref('');
		// const first_name: Ref<string> = ref('');
		// const last_name: Ref<string> = ref('');
		// const email: Ref<string> = ref('');
		// const student_id: Ref<string> = ref('');
		// const role: Ref<string> = ref('student');

		const store = useStore();

		return {
			user,
			// login,
			// first_name,
			// last_name,
			// email,
			// student_id,
			// role,
			roles: computed( () => {
				const role_setting = store.state.settings.course_settings
					.find( (_setting: CourseSetting) => _setting.var === 'roles');
				return role_setting && role_setting.value || [];
			}),
			addUser: () => {
				console.log('adding User');
				// const user = {
				// 	login: login,
				// 	first_name: first_name,
				// 	last_name: last_name,
				// 	email: email,
				// 	student_id: student_id,
				// 	role: role
				// }
				void store.dispatch('user/addUser',user);
			}
		}
	}
});
</script>
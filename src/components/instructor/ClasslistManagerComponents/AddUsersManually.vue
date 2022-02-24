<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col">
						<q-input
							outlined
							v-model="merged_user.username"
							label="Username *"
							@blur="checkUser"
							ref="username_ref"
							lazy-rules
							:rules="[(val) => validateUsername(val)]"
						/>
					</div>
					<div class="col">
						<q-input outlined v-model="merged_user.first_name" label="First Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input outlined v-model="merged_user.last_name" label="Last Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input outlined v-model="merged_user.email" label="Email" :disable="user_exists" />
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-input outlined v-model="merged_user.student_id" label="Student ID" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="merged_user.recitation" label="Recitation" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="merged_user.section" label="Section" :disable="user_exists" />
					</div>
					<div class="col">
						<q-select
							outlined
							ref="role_ref"
							v-model="merged_user.role"
							:options="roles"
							label="Role *"
							:validate="validateRole"
							:rules="[(val) => validateRole(val)]"
							/>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Add This User and Another One" @click="addUser(false)" />
				<q-btn flat label="Add This User and Close" @click="addUser(true)" />
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">

import { defineComponent, ref, computed } from 'vue';
import { useQuasar } from 'quasar';
import { logger } from 'boot/logger';

import { checkIfUserExists } from 'src/common/api-requests/user';
import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import { useSettingsStore } from 'src/stores/settings';

import { MergedUser, ParseableMergedUser, User } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { AxiosError } from 'axios';
import { parseUsername } from 'src/common/models/parsers';

interface QRef {
	validate: () => boolean;
	hasError: string;
}

export default defineComponent({
	name: 'AddUsersManually',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const merged_user = ref<ParseableMergedUser>({});
		const user_exists = ref<boolean>(true);
		const username_ref = ref<QRef | null>(null);
		const role_ref = ref<QRef | null>(null);
		const users = useUserStore();
		const session = useSessionStore();
		const settings = useSettingsStore();

		return {
			merged_user,
			user_exists,
			username_ref,
			role_ref,
			// see if the user exists already and fill in the known fields
			checkUser: async () => {
				// If the user doesn't exist, the catch statement will handle this.
				try {
					const course_id = session.course.course_id;
					const user_params = await checkIfUserExists(course_id, merged_user.value.username ?? '');
					const user = new User(user_params);

					user_exists.value = true;
					merged_user.value.user_id = user.user_id;
					merged_user.value.username = user.username;
					merged_user.value.first_name = user.first_name;
					merged_user.value.last_name = user.last_name;
					merged_user.value.email = user.email;
				} catch (err) {
					const error = err as ResponseError;
					// this will occur is the user is not a global user
					if (error.exception === 'DB::Exception::UserNotFound') {
						user_exists.value = false;
					} else {
						logger.error(error.message);
					}
				}
			},
			// Return an array of the roles in the course.
			roles: computed(() =>
				(settings.getCourseSetting('roles').value as string[]).filter(v => v !== 'admin')),
			addUser: async (close: boolean) => {
				try {
					// Check to ensure username is correct and a role is selected.
					if (username_ref.value && role_ref.value) {
						username_ref.value.validate();
						role_ref.value.validate();
						if (username_ref.value.hasError || role_ref.value.hasError) {
							return;
						}
					}
					merged_user.value.course_id = session.course.course_id;
					const user = await users.addMergedUser(new MergedUser(merged_user.value));
					$q.notify({
						message: `The user with username '${user.username ?? ''}' was added successfully.`,
						color: 'green'
					});
					if (close) {
						context.emit('closeDialog');
					} else {
						merged_user.value = { username: '__NEW__' };
					}
				} catch (err) {
					const error = err as AxiosError;
					logger.error(error);
					const data = error?.response?.data as ResponseError || { exception: '' };
					$q.notify({
						message: data.exception,
						color: 'red'
					});
				}
			},
			validateRole: (val: string | null) => {
				if (val == undefined) {
					return 'You must select a role';
				}
				return true;
			},
			validateUsername: (val: string) => {
				try {
					const username = parseUsername(val);
					if (users.merged_users.findIndex(u => u.username === username) >= 0) {
						return 'This user is already in the course.';
					}
					return true;
				} catch (err) {
					return 'This is not a valid username';
				}
			}
		};
	}
});
</script>

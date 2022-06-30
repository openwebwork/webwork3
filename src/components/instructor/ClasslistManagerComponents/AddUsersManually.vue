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

<script setup lang="ts">

import { ref, computed, defineEmits } from 'vue';
import { useQuasar } from 'quasar';
import { logger } from 'boot/logger';

import { checkIfUserExists } from 'src/common/api-requests/user';
import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import { useSettingsStore } from 'src/stores/settings';

import { CourseUser, ParseableCourseUser, User } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import { AxiosError } from 'axios';
import { parseNonNegInt, parseUsername } from 'src/common/models/parsers';

interface QRef {
	validate: () => boolean;
	hasError: string;
}

const emit = defineEmits(['closeDialog']);

const $q = useQuasar();
const merged_user = ref<ParseableCourseUser>({});
const user_exists = ref<boolean>(true);
const username_ref = ref<QRef | null>(null);
const role_ref = ref<QRef | null>(null);
const users = useUserStore();
const session = useSessionStore();
const settings = useSettingsStore();

// see if the user exists already and fill in the known fields
const checkUser = async () => {
	const user = await checkIfUserExists(session.course.course_id, merged_user.value.username ?? '');
	if (user.username == undefined) {
		user_exists.value = false;
	} else {
		user_exists.value = true;
		merged_user.value = user;
	}
};

// Return an array of the roles in the course.
const roles = computed(() =>
	(settings.getCourseSetting('roles').value as string[]).filter(v => v !== 'admin'));

const addUser = async (close: boolean) => {
	try {
		// Check to ensure username is correct and a role is selected.
		if (username_ref.value && role_ref.value) {
			username_ref.value.validate();
			role_ref.value.validate();
			if (username_ref.value.hasError || role_ref.value.hasError) return;
		}

		// if the user is not global, add them.
		if (!user_exists.value) {
			try {
				logger.debug(`Trying to add the new global user ${merged_user.value.username ?? 'UNKNOWN'}`);
				const global_user = await users.addUser(new User(merged_user.value));
				const msg = `The global user with username ${global_user?.username ?? 'UNKNOWN'} was created.`;
				$q.notify({ message: msg, color: 'green' });
				logger.debug(msg);
				merged_user.value.user_id = global_user?.user_id;
			} catch (err) {
				const error = err as ResponseError;
				$q.notify({ message: error.message, color: 'red' });
			}
		}

		merged_user.value.course_id = session.course.course_id;
		await users.addCourseUser(new CourseUser(merged_user.value)).then((course_user) => {
			const u = users.findCourseUser({ user_id: parseNonNegInt(course_user.user_id ?? 0) });
			// The global user needs to be added to the store as well.
			users.users.push(new User(merged_user.value));
			$q.notify({
				message: `The user with username '${u.username ?? ''}' was added successfully.`,
				color: 'green'
			});
		});

		if (close) {
			emit('closeDialog');
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
};

const validateRole = (val: string | null) => {
	if (val == undefined) {
		return 'You must select a role';
	}
	return true;
};

const validateUsername = (val: string) => {
	try {
		const username = parseUsername(val);
		if (users.course_users.findIndex(u => u.username === username) >= 0) {
			return 'This user is already in the course.';
		}
		return true;
	} catch (err) {
		return 'This is not a valid username';
	}
};
</script>

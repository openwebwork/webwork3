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
							v-model="course_user.username"
							label="Username *"
							@blur="checkUser"
							ref="username_ref"
							lazy-rules
							:rules="[val => validateUsername(val)]"
						/>
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.first_name" label="First Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.last_name" label="Last Name" :disable="user_exists"/>
					</div>
					<div class="col">
						<q-input
							outlined
							v-model="course_user.email"
							label="Email"
							lazy-rules
							:rules="[val => validateEmail(val)]"
							:disable="user_exists"
						/>
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-input outlined v-model="course_user.student_id" label="Student ID" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.recitation" label="Recitation" :disable="user_exists" />
					</div>
					<div class="col">
						<q-input outlined v-model="course_user.section" label="Section" :disable="user_exists" />
					</div>
					<div class="col">
						<q-select
							outlined
							ref="role_ref"
							v-model="course_user.role"
							:options="roles"
							label="Role *"
							:validate="validateRole"
							:rules="[val => validateRole(val)]"
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

import { CourseUser, User } from 'src/common/models/users';
import type { ResponseError } from 'src/common/api-requests/errors';
import { isValidEmail, isValidUsername, parseNonNegInt } from 'src/common/models/parsers';

interface QRef {
	validate: () => boolean;
	hasError: string;
}

const emit = defineEmits(['closeDialog']);

const $q = useQuasar();
const course_user = ref<CourseUser>(new CourseUser());
const user_exists = ref<boolean>(true);
const username_ref = ref<QRef | null>(null);
const role_ref = ref<QRef | null>(null);
const user_store = useUserStore();
const session = useSessionStore();
const settings = useSettingsStore();

// see if the user exists already and fill in the known fields
const checkUser = async () => {
	const existing_user = await checkIfUserExists(session.course.course_id, course_user.value.username);
	if (existing_user.username) {
		course_user.value.set(existing_user);
		user_exists.value = true;
	} else {
		// make sure the other fields are emptied.  This can happen if they were prefilled.
		course_user.value = new CourseUser({ username: course_user.value.username });
		user_exists.value = false;
	}
};

// Return an array of the roles in the course.
const roles = computed(() =>
	(settings.getCourseSetting('roles').value as string[]).filter(v => v !== 'admin'));

const addUser = async (close: boolean) => {

	// Check that the user fields are valid.
	if (! course_user.value.isValid()) {
		if (username_ref.value && role_ref.value) {
			username_ref.value.validate();
			role_ref.value.validate();
		}
		return;
	}

	// if the user is not global, add them.
	if (!user_exists.value) {
		try {
			logger.debug(`Trying to add the new global user ${course_user.value.username ?? 'UNKNOWN'}`);
			const global_user = await user_store.addUser(new User(course_user.value));
			if (global_user == undefined) throw `There is an error adding the user ${course_user.value.username}`;
			const msg = `The global user with username ${global_user?.username ?? 'UNKNOWN'} was created.`;
			$q.notify({ message: msg, color: 'green' });
			logger.debug(msg);
			course_user.value.user_id = global_user.user_id;
		} catch (err) {
			const error = err as ResponseError;
			$q.notify({ message: error.message, color: 'red' });
		}
	}

	course_user.value.course_id = session.course.course_id;
	const user = await user_store.addCourseUser(new CourseUser(course_user.value));

	// If the user exist globally, fetch the user to be added to the store
	if (user_exists.value) {
		await user_store.fetchUser(user.user_id);
	}
	const u = user_store.findCourseUser({ user_id: parseNonNegInt(user.user_id ?? 0) });
	$q.notify({
		message: `The user with username '${u.username ?? ''}' was added successfully.`,
		color: 'green'
	});
	if (close) {
		emit('closeDialog');
	} else {
		course_user.value = new CourseUser();
	}
};

const validateRole = (val: string | null) => {
	if (val == undefined || val == 'UNKNOWN') {
		return 'You must select a role';
	}
	return true;
};

const validateUsername = (username: string) => {
	if (user_store.course_users.findIndex(u => u.username === username) >= 0) {
		return 'This user is already in the course.';
	}
	if (isValidUsername(username)) return true;
	return 'This is not a valid username';
};

const validateEmail = (val: string) => {
	if (isValidEmail(val)) return true;
	return 'The email is not a valid form.';
};
</script>

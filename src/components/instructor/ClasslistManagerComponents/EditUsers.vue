<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Edit Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col header">Username</div>
					<div class="col header">First Name</div>
					<div class="col header">Last Name</div>
					<div class="col header">Student ID</div>
					<div class="col header">Course Role</div>
					<div class="col header">Section</div>
					<div class="col header">Recitation</div>
				</div>
				<div class="row" v-for="user in merged_users" :key="user.username">
					<div class="col"> {{ user.username }} </div>
					<div class="col"> {{ user.first_name }} </div>
					<div class="col"> {{ user.last_name }} </div>
					<div class="col"> {{ user.student_id }} </div>
					<div class="col">
						<q-select :options="roles" v-model="user.role"/>
					</div>
					<div class="col">
						<q-input v-model="user.section"/>
					</div>
					<div class="col">
						<q-input v-model="user.recitation"/>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Save Changes and Close" @click="updateUsers"/>
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>

		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { useQuasar } from 'quasar';

import { MergedUser, CourseUser } from 'src/common/models/users';
import { useUserStore } from 'src/stores/users';
import { logger } from 'boot/logger';
import { useSettingsStore } from 'src/stores/settings';

export default defineComponent({
	props: {
		users_to_edit: {
			type: Array,
			required: true
		}
	},
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();

		const users = (props.users_to_edit as MergedUser[]).map(u => u.clone());

		const merged_users = ref<Array<MergedUser>>(users);
		const store_users = useUserStore();
		const settings = useSettingsStore();

		const updateUsers = async () => {
			const promises: Array<Promise<void>> = [];
			merged_users.value.forEach(_user => {
				// First, only pick the fields from a CourseUser object:
				const course_user = _user.toObject(CourseUser.ALL_FIELDS);
				promises.push(store_users.updateCourseUser(new CourseUser(course_user)));
				logger.info(`[EditUsers/updateUsers]: user ${_user.username ?? ''} updated.`);
				// Additionally, update the merged user in the store.
				void store_users.updateMergedUser(new MergedUser(_user));
			});
			await Promise.all(promises)
				.then(() => {
					const usernames = merged_users.value.map(_merged_user => _merged_user.username);
					$q.notify({
						message: `The users ${usernames.join(', ')} were updated`,
						color: 'green'
					});
				})
				.catch((reason: Error) => {
					$q.notify({
						message: reason.message,
						color: 'red',
					});
				});
			context.emit('closeDialog');
		};

		return {
			merged_users,
			updateUsers,
			// This is just copied over from AddUsersManually.  Perhaps put in a central location.
			roles: computed(() =>
				(settings.getCourseSetting('roles').value as string[]).filter(v => v !== 'admin')),
		};
	}
});
</script>

<style lang="css" @scoped>
.header {
	font-weight: bold;
}
</style>

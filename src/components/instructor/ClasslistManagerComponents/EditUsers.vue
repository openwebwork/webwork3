<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col header">Username</div>
					<div class="col header">First Name</div>
					<div class="col header">Last Name</div>
					<div class="col header">Course Role</div>
					<div class="col header">Section</div>
					<div class="col header">Recitation</div>
				</div>
				<div class="row" v-for="user in merged_users" :key="user.username">
					<div class="col"> {{ user.username}} </div>
					<div class="col"> {{ user.first_name}} </div>
					<div class="col"> {{ user.last_name}} </div>
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
import { cloneDeep, clone, remove, pick } from 'lodash-es';

import { MergedUser } from 'src/store/models/users';
import { CourseSetting } from 'src/store/models/settings';
import { useStore } from 'src/store';
import { logger } from 'boot/logger';
import { CourseUser } from 'src/store/models/users';

export default defineComponent({
	props: {
		users_to_edit: Array,
	},
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();

		const merged_users =
			ref<Array<MergedUser>>(
				props.users_to_edit
					? cloneDeep(props.users_to_edit) as unknown as Array<MergedUser>
					: []
			);
		const store = useStore();

		const updateUsers = async () => {

			const promises: Array<Promise<void>> = [];
			merged_users.value.forEach(_user => {
				const u = pick(_user, CourseUser.ALL_FIELDS);
				promises.push(store.dispatch('users/updateCourseUser', u));
				logger.info(`[EditUsers/updateUsers]: user ${_user.username ?? ''} updated.`);
				void store.dispatch('users/updateMergedUser', _user);
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
			// this is just copied over from AddUsersManually. perhaps put in a central location.
			roles: computed(() => { // return an array of the roles in the course
				const all_roles = store.state.settings.course_settings.find(
					(_setting: CourseSetting) => _setting.var === 'roles'
				);
				const r = clone(all_roles?.value as Array<string>);
				remove(r, v => v === 'admin'); // don't allow to set admin level here.
				return r;
			}),
		};
	}
});
</script>

<style lang="css" @scoped>
.header {
	font-weight: bold;
}
</style>

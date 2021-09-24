<template>
	<div>
		<div class="q-pa-lg">
			<q-table
				:columns="columns"
				:rows="detailed_course_users"
				row-key="user_id"
				title="Users"
				selection="multiple"
				:filter="filter"
				:visible-columns="['username', 'first_name', 'last_name', 'email', 'role']"
				v-model:selected="selected"
			>
				<template v-slot:top-right>
					<span v-if="selected.length > 0" style="margin-right: 20px">
						<q-btn color="secondary" label="Deleted Selected" @click="deleteCourseUsers" />
						<q-btn color="secondary" label="Edit Selected" />
					</span>
					<q-input dense debounce="300" v-model="filter" placeholder="Search">
						<template v-slot:append>
							<q-icon name="search" />
						</template>
					</q-input>
					<span style="margin-left: 20px">
						<q-btn-dropdown color="primary" label="Add Users">
							<q-list>
								<q-item clickable v-close-popup @click="open_users_manually = true">
									<q-item-section>
										<q-item-label>Add Users Manually</q-item-label>
									</q-item-section>
								</q-item>
								<q-item clickable v-close-popup @click="open_users_from_file = true">
									<q-item-section>
										<q-item-label>Add Users from File</q-item-label>
									</q-item-section>
								</q-item>
							</q-list>
						</q-btn-dropdown>
					</span>
				</template>
			</q-table>
		</div>
		<q-dialog v-model="open_users_manually">
			<add-users-manually @close-dialog="open_users_manually = false" />
		</q-dialog>
		<q-dialog full-width v-model="open_users_from_file">
			<add-users-from-file />
		</q-dialog>
	</div>
</template>

<script lang="ts">
import { useQuasar } from 'quasar';
import { defineComponent, computed, ref, Ref } from 'vue';
import { assign } from 'lodash-es';

import { useStore } from 'src/store';
import { api } from 'boot/axios';
import { User, CourseUser, UserCourse, DetailedCourseUser, ResponseError } from 'src/store/models';
import { newDetailedCourseUser } from 'src/store/utils/users';
import AddUsersManually from './AddUsersManually.vue';
import AddUsersFromFile from './AddUsersFromFile.vue';

export default defineComponent({
	name: 'ClasslistManager',
	components: {
		AddUsersManually,
		AddUsersFromFile
	},
	emits: ['closeDialog'],
	setup() {
		const $q = useQuasar();
		const store = useStore();
		const selected: Ref<Array<User>> = ref([]);
		const filter: Ref<string> = ref('');
		const open_users_manually: Ref<boolean> = ref(false);
		const open_users_from_file: Ref<boolean> = ref(false);

		const columns = [
			{
				name: 'username',
				label: 'username',
				field: 'username',
				sortable: true
			},
			{
				name: 'first_name',
				label: 'First Name',
				field: 'first_name',
				sortable: true
			},
			{
				name: 'last_name',
				label: 'Last Name',
				field: 'last_name',
				sortable: true
			},
			{
				name: 'email',
				label: 'Email',
				field: 'email',
				sortable: true
			},
			{
				name: 'user_id',
				label: 'user_id',
				field: 'user_id',
				sortable: true
			},
			{
				name: 'role',
				label: 'Role',
				field: 'role',
				sortable: true
			}
		];
		return {
			filter,
			selected,
			open_users_manually,
			open_users_from_file,
			columns,
			detailed_course_users: computed(() => {
				const dcu: Array<DetailedCourseUser> = [];
				store.state.users.course_users.forEach((_course_user: CourseUser) => {
					const _user = store.state.users.users.find((_u: User) => _u.user_id === _course_user.user_id);
					const course_user = newDetailedCourseUser();
					assign(course_user, _user, _course_user);
					dcu.push(course_user);
				});
				return dcu;
			}),
			deleteCourseUsers: async () => {
				const users_to_delete = selected.value.map((u) => u.username).join(', ');
				var conf = confirm(`Are you sure you want to delete the users: ${users_to_delete}`);
				if (conf) {
					for await (const _user_to_delete of selected.value) {
						try {
							await store.dispatch('users/deleteCourseUser', _user_to_delete);
							$q.notify({
								message: `The user '${_user_to_delete.username}' ` +
									'has been succesfully deleted from the course.',
								color: 'green'
							});
						} catch (err) {
							const error = err as ResponseError;
							$q.notify({ message: error.message, color: 'red' });
						}
						// delete the user if they have no other courses
						const response = await api.get(`users/${_user_to_delete.user_id}/courses`);
						const user_courses = response.data as  Array<UserCourse>;

						if (user_courses.length === 0){
							try {
								await store.dispatch('users/deleteUser', _user_to_delete);
								$q.notify({
									message: `The user '${_user_to_delete.username}' has been succesfully deleted.`,
									color: 'green'
								});
							} catch (err) {
								const error = err as ResponseError;
								$q.notify({ message: error.message, color: 'red' });
							}
						}
					}
				}
			}
		};
	}
});
</script>

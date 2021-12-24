<template>
	<q-page>
		<div class="q-pa-lg">
			<q-table
				:columns="columns"
				:rows="merged_users"
				row-key="user_id"
				title="Users"
				selection="multiple"
				:filter="filter"
				:visible-columns="['username', 'first_name', 'last_name', 'email', 'student_id',
					'section', 'recitation', 'role']"
				v-model:selected="selected"
			>
				<template v-slot:top-right>
					<span v-if="selected.length > 0" style="margin-right: 20px">
						<q-btn color="secondary" label="Deleted Selected" @click="deleteCourseUsers" />
						<q-btn color="secondary" label="Edit Selected" @click="open_edit_dialog = true" />
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
		<q-dialog full-width v-model="open_users_manually">
			<add-users-manually @close-dialog="open_users_manually = false" />
		</q-dialog>
		<q-dialog full-width v-model="open_users_from_file" >
			<add-users-from-file @close-dialog="open_users_from_file = false"/>
		</q-dialog>
		<q-dialog full-width v-model="open_edit_dialog">
			<edit-users :users_to_edit="selected" @close-dialog="open_edit_dialog = false"/>
		</q-dialog>
	</q-page>
</template>

<script lang="ts">
import { useQuasar } from 'quasar';
import { defineComponent, computed, ref } from 'vue';

import { pick } from 'lodash-es';
import { useStore } from 'src/store';
import { api } from 'boot/axios';
import { MergedUser, CourseUser } from 'src/store/models/users';
import { UserCourse } from 'src/store/models/courses';
import { ResponseError } from 'src/store/models';
import AddUsersManually from 'src/components/instructor/ClasslistManagerComponents/AddUsersManually.vue';
import AddUsersFromFile from 'src/components/instructor/ClasslistManagerComponents/AddUsersFromFile.vue';
import EditUsers from 'src/components/instructor/ClasslistManagerComponents/EditUsers.vue';

export default defineComponent({
	name: 'ClasslistManager',
	components: {
		AddUsersManually,
		AddUsersFromFile,
		EditUsers
	},
	emits: ['closeDialog'],
	setup() {
		const $q = useQuasar();
		const store = useStore();
		const selected = ref<Array<MergedUser>>([]);
		const filter = ref<string>('');
		const open_users_manually = ref<boolean>(false);
		const open_users_from_file = ref<boolean>(false);
		const open_edit_dialog = ref<boolean>(false);

		const columns = [
			{
				name: 'username',
				label: 'Username',
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
				name: 'student_id',
				label: 'Student ID',
				field: 'student_id',
				sortable: true
			},
			{
				name: 'section',
				label: 'Section',
				field: 'section',
				sortable: true
			},
			{
				name: 'recitation',
				label: 'Recitation',
				field: 'recitation',
				sortable: true
			},
			{
				name: 'user_id',
				field: 'user_id',
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
			open_edit_dialog,
			columns,
			merged_users: computed(() => store.state.users.merged_users),
			deleteCourseUsers: async () => {
				const users_to_delete = selected.value.map((u) => u.username).join(', ');
				var conf = confirm(`Are you sure you want to delete the users: ${users_to_delete}`);
				if (conf) {
					for await (const _user of selected.value) {
						const username = _user.username as string;
						const _user_to_delete = pick(_user, CourseUser.ALL_FIELDS) as CourseUser;

						try {

							await store.dispatch('users/deleteCourseUser', _user_to_delete);
							$q.notify({
								message: `The user '${username}' has been succesfully deleted from the course.`,
								color: 'green'
							});
						} catch (err) {
							const error = err as ResponseError;
							$q.notify({ message: error.message, color: 'red' });
						}
						// delete the user if they have no other courses
						const user_id = _user_to_delete.user_id as number;
						const response = await api.get(`users/${user_id}/courses`);
						const user_courses = response.data as  Array<UserCourse>;

						if (user_courses.length === 0) {
							try {
								await store.dispatch('users/deleteUser', _user_to_delete);
								$q.notify({
									message: `The user '${username}' has been succesfully deleted.`,
									color: 'green'
								});
							} catch (err) {
								const error = err as ResponseError;
								$q.notify({ message: error.message, color: 'red' });
							}
						}
						void store.dispatch('users/deleteMergedCourseUser', _user);
						selected.value = [];
					}
				}
			}
		};
	}
});
</script>

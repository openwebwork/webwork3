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

<script setup lang="ts">
import { useQuasar } from 'quasar';
import { computed, ref, watch } from 'vue';

import { useUserStore } from 'src/stores/users';
import { api } from 'boot/axios';
import { logger } from 'src/boot/logger';

import { User, MergedUser, CourseUser } from 'src/common/models/users';
import { UserCourse } from 'src/common/models/courses';
import type { ResponseError } from 'src/common/api-requests/interfaces';
import AddUsersManually from 'src/components/instructor/ClasslistManagerComponents/AddUsersManually.vue';
import AddUsersFromFile from 'src/components/instructor/ClasslistManagerComponents/AddUsersFromFile.vue';
import EditUsers from 'src/components/instructor/ClasslistManagerComponents/EditUsers.vue';

const $q = useQuasar();
const users = useUserStore();
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

watch(() => open_edit_dialog.value, () => {
	// When the Edit Users Dialog closes clear the selected row.
	if (!open_edit_dialog.value) selected.value = [];
});

const merged_users = computed(() => users.merged_users);

const deleteCourseUsers = () => {
	const users_to_delete = selected.value.map((u) => u.username).join(', ');
	$q.dialog({
		message: `Are you sure you want to delete the users: ${users_to_delete}`,
		cancel: true,
		persistent: true
	}).onOk(() => {
		for (const user of selected.value) {
			users.deleteCourseUser(new CourseUser(user)).then(() => {
				$q.notify({
					message: `The user '${
						user.username ?? ''}' has been succesfully deleted from the course.`,
					color: 'green'
				});
			}).catch((err) => {
				const error = err as ResponseError;
				$q.notify({ message: error.message, color: 'red' });
			});

			// Delete the user if they have no other courses
			api.get(`users/${user.user_id ?? ''}/courses`).then((response) => {
				const user_courses = response.data as  Array<UserCourse>;

				if (user_courses.length === 0) {
					users.deleteUser(new User(user)).then(() => {
						$q.notify({
							message: `The global user '${user.username ?? ''}'` +
											' has been succesfully deleted.',
							color: 'green'
						});
					}).catch((err) => {
						const error = err as ResponseError;
						$q.notify({ message: error.message, color: 'red' });
					});
				}
				selected.value = [];
			}).catch((err) => {
				logger.error(err);
			});
		}
	});
};
</script>

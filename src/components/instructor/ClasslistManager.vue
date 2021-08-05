<template>
	<div>
		<div class="q-pa-lg">
			<q-table
				:columns="columns"
				:rows="users"
				row-key="user_id"
				title="Users"
				selection="single"
				:filter="filter"
				:visible-columns="['login','email']"
				v-model:selected="selected"
			>
				<template v-slot:top-right>
					<span v-if="selected.length>0" style="margin-right: 20px">
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
		<q-dialog full-width v-model="open_users_manually">
			<add-users-manually />
		</q-dialog>
		<q-dialog full-width v-model="open_users_from_file">
			<add-users-from-file />
		</q-dialog>

	</div>
</template>

<script lang="ts">
import { defineComponent, computed, ref, Ref } from 'vue';
import { useStore } from '../../store';
import { User } from '../../store/models';
import AddUsersManually from './AddUsersManually.vue';
import AddUsersFromFile from './AddUsersFromFile.vue';

export default defineComponent({
	name: 'ClasslistManager',
	components: {
		AddUsersManually,
		AddUsersFromFile
	},
	setup() {
		const store = useStore();
		const selected: Ref<Array<User>> = ref([]);
		const filter: Ref<string> = ref('');
		const open_users_manually: Ref<boolean> = ref(false);
		const open_users_from_file: Ref<boolean> = ref(false);
		const columns = [
			{
				name: 'login',
				label: 'Login',
				field: 'login',
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
				sortable: true,
			}];
		return {
			filter,
			selected,
			open_users_manually,
			open_users_from_file,
			columns,
			users: computed( () => store.state.user.users),
		}

	}
});
</script>
<template>
	<div>
		<q-card style="width: 600px">
			<q-card-section>
				<div class="text-h6">Add Users</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col header">Username</div>
					<div class="col header">First Name</div>
					<div class="col header">Last Name</div>
					<div class="col header">Course Role</div>
				</div>
				<div class="row" v-for="user in merged_users" :key="user.username">
					<div class="col"> {{ user.username}} </div>
					<div class="col"> {{ user.first_name}} </div>
					<div class="col"> {{ user.last_name}} </div>
					<div class="col">
						<q-select :options="roles" v-model="user.role"/>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Save Changes and Close"/>
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>

		</q-card>
	</div>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, computed } from 'vue';
import { cloneDeep, clone, remove } from 'lodash-es';

import { MergedCourseUser, CourseSetting } from 'src/store/models';
import { useStore } from 'src/store';

export default defineComponent({
	props: {
		users_to_edit: Array,
	},
	setup(props) {
		const merged_users: Ref<Array<MergedCourseUser>> = props.users_to_edit ?
			ref(cloneDeep(props.users_to_edit) as unknown as Array<MergedCourseUser>) : ref([]);
		const store = useStore();
		return {
			merged_users,
			// this is just copied over from AddUsersManually. perhaps put in a central location.
			roles: computed(() => { // return an array of the roles in the course
				const all_roles = store.state.settings.course_settings.find(
					(_setting: CourseSetting) => _setting.var === 'roles'
				);
				const r = clone(all_roles?.value as Array<string>);
				remove(r, v => v==='admin'); // don't allow to set admin level here.
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

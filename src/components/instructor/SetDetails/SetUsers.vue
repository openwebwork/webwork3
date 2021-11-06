<template>
	<q-table
		title="User Overrides"
		:rows="users"
		:columns="columns"
		row-key="user_id"
		selection="multiple"
		v-model:selected="assigned"
	/>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';
import type { Ref } from 'vue';
import { useStore } from '@/store';
import { useRoute } from 'vue-router';
import { logger } from '@/boot/logger';
import { MergedUser } from '@/store/models/users';
import { ProblemSet } from '@/store/models/problem_sets';
import { parseNonNegInt } from '@/store/models';

export default defineComponent({
	name: 'SetUsers',
	setup() {
		const store = useStore();
		const route = useRoute();
		const assigned: Ref<Array<MergedUser>> = ref([]);
		const problem_set: Ref<ProblemSet> = ref(new ProblemSet());
		const columns = [
			{ name: 'first_name', label: 'First Name', field: 'first_name' },
			{ name: 'last_name', label: 'Last Name', field: 'last_name' }
		];

		const updateProblemSet = () => {
			if (route.params.set_id) {
				problem_set.value = store.state.problem_sets.problem_sets.find(
					_set => _set.set_id === parseNonNegInt(route.params.set_id as string)
				) ?? new ProblemSet();
			}
			if (problem_set.value.set_id && problem_set.value.set_id > 0) {
				if (problem_set.value.set_type === 'HW') {
					columns.splice(columns.length, 0,
						{ name: 'open_date', label: 'Open Date', field: 'set_dates.open_date' },
						{ name: 'due_date', label: 'Due Date', field: 'set_dates.due_date' },
						{ name: 'answer_date', label: 'Answer Date', field: 'set_dates.answer_date' }
					);
				}
			}
		};
		updateProblemSet();
		watch([store.state.problem_sets.user_sets], updateProblemSet);
		console.log(problem_set.value);

		// fill the assigned array with users that have been assigned to the set
		assigned.value = store.state.users.merged_users.filter(
			user => store.state.problem_sets.user_sets
				.findIndex(_user_set => _user_set.course_user_id === user.course_user_id) > -1
		);
		return {
			columns,
			users: computed(() => store.state.users.merged_users),
			set_users: computed(() => store.state.problem_sets.user_sets),
			assigned
		};
	},
	async created() {
		// fetch the user sets for this set
		const store = useStore();
		const route = useRoute();
		if(route.params.set_id) {
			logger.debug('Loading UserSets');
			await store.dispatch('problem_sets/fetchUserSets', {
				course_id: route.params.course_id,
				set_id: route.params.set_id
			});
		}
	}
});
</script>

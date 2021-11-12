<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><q-input v-model="set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="set.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="set.set_visible" /></td>
		</tr>
		<tr>
			<td class="header">Enable Reduced Scoring</td>
			<td><q-toggle v-model="set.set_params.enable_reduced_scoring" /></td>
		</tr>
		<homework-dates v-if="set"
			:dates="set.set_dates"
			:reduced_scoring="set.set_params.enable_reduced_scoring"
			/>
		<tr>
			<td class="header">Other</td>
			<td><q-toggle v-model="set.set_params.allow" /></td>
		</tr>
	</table>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, watch, toRefs } from 'vue';
import { useQuasar } from 'quasar';
import { cloneDeep, pick } from 'lodash-es';

import { HomeworkSet } from '@/store/models/problem_sets';
import { useStore } from '@/store';
import HomeworkDates from './HomeworkDates.vue';

export default defineComponent({
	components: {
		HomeworkDates
	},
	name: 'HomeworkSet',
	props: {
		set_id: Number
	},
	setup(props) {
		const store = useStore();
		const $q = useQuasar();

		const { set_id } = toRefs(props);
		const set: Ref<HomeworkSet> = ref(new HomeworkSet());

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id === set_id.value) ??
				new HomeworkSet();
			// need a copy since we can't modify the one in the store
			set.value = cloneDeep(s as HomeworkSet);
		};

		watch(()=>set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set.value), (new_set, old_set) => {
			// don't update if the homework set changes.
			if (new_set.set_id == old_set.set_id) {
				// cloning above in the watch statement changes that it is a HomeworkSet
				const _set = new HomeworkSet(pick(new_set, HomeworkSet.ALL_FIELDS));
				if (_set.isValid()) { // check that the dates are valid
					void store.dispatch('problem_sets/updateSet', _set.toObject());
					$q.notify({
						message: `The problem set '${new_set.set_name ?? ''}' was successfully updated.`,
						color: 'green'
					});
				}
			}
		},
		{ deep: true });

		return {
			set,
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
		};
	}
});
</script>

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
		<tr>
			<td class="header">Open Date</td>
			<td><date-time-input v-model="set.set_dates.open" :rules="checkDates"/></td>
		</tr>
		<tr v-if="set.set_params.enable_reduced_scoring">
			<td class="header">Reduced Scoring Date</td>
			<td><date-time-input v-model="set.set_dates.reduced_scoring" :rules="checkDates"/></td>
		</tr>
		<tr>
			<td class="header">Due Date</td>
			<td><date-time-input v-model="set.set_dates.due" :rules="checkDates"/></td>
		</tr>
		<tr>
			<td class="header">Answer Date</td>
			<td><date-time-input v-model="set.set_dates.answer" :rules="checkDates"/></td>
		</tr>
	</table>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, watch, toRefs } from 'vue';
import { useQuasar } from 'quasar';
import { cloneDeep, pick } from 'lodash-es';

import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { HomeworkSet } from '@/store/models/problem_sets';
import { useStore } from '@/store';

export default defineComponent({
	components: { DateTimeInput },
	name: 'HomeworkSet',
	props: {
		set_id: Number
	},
	setup(props) {
		const store = useStore();
		const $q = useQuasar();

		const { set_id } = toRefs(props);
		const hw: Ref<HomeworkSet> = ref(new HomeworkSet());

		const set = ref(hw);

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id === set_id.value) ||
				new HomeworkSet();
			set.value = cloneDeep(s as HomeworkSet);
		};

		watch(()=>set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set.value), (new_set, old_set) => {
			if (new_set.set_id == old_set.set_id) {
				void store.dispatch('problem_sets/updateSet', pick(new_set, HomeworkSet.ALL_FIELDS));
				$q.notify({
					message: `The problem set '${new_set.set_name ?? ''}' was successfully updated.`,
					color: 'green'
				});

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
			checkDates: [
				() => {
					const d = set.value.set_dates;
					const p = set.value.set_params;
					return p.enable_reduced_scoring && d.reduced_scoring ?
						(d.open <= d.reduced_scoring && d.reduced_scoring <= d.due  && d.due <= d.answer) :
						(d.open <= d.due && d.due <= d.answer)
						|| 'The dates must be in order';
				}
			]
		};
	}
});
</script>

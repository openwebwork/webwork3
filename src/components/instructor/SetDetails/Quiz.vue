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
			<td class="header">Open Date</td>
			<td><date-time-input v-model="set.dates.open" /></td>
		</tr>
		<tr>
			<td class="header">Due Date</td>
			<td><date-time-input v-model="set.dates.due" /></td>
		</tr>
		<tr>
			<td class="header">Answer Date</td>
			<td><date-time-input v-model="set.dates.answer" /></td>
		</tr>
		<tr>
			<td class="header">Timed</td>
			<td><q-toggle v-model="set.params.timed" /></td>
		</tr>
	</table>
</template>

<script lang="ts">
import { defineComponent, reactive, watch, toRefs } from 'vue';
import { useQuasar } from 'quasar';
import { cloneDeep } from 'lodash-es';

import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { ProblemSet } from 'src/store/models';
import { newProblemSet, copyProblemSet } from 'src/store/common';
import { useStore } from 'src/store';

export default defineComponent({
	components: { DateTimeInput },
	name: 'Quiz',
	props: {
		set_id: Number
	},
	setup(props) {
		const store = useStore();
		const $q = useQuasar();

		const { set_id } = toRefs(props);

		const set: ProblemSet = reactive(newProblemSet());

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id == set_id.value) ||
				newProblemSet();
			copyProblemSet(set, s);
		};

		watch(()=>set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set), (new_set, old_set) => {
			if (new_set.set_id == old_set.set_id) {
				void store.dispatch('problem_sets/updateSet', new_set);
				$q.notify({
					message: `The problem set ${new_set.set_name} was successfully updated.`,
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
			]
		};
	}
});
</script>

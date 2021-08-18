<template>
	<table id="modelValuetable">
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
			<td><q-toggle v-model="set.params.enable_reduced_scoring" /></td>
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
	</table>
</template>

<script lang="ts">
import { defineComponent, reactive, watch, toRefs } from 'vue';
import { useQuasar } from 'quasar';
import { cloneDeep } from 'lodash';

import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { ProblemSet } from 'src/store/models';
import { newProblemSet } from 'src/store/common';
import { useStore } from 'src/store';

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

		const set: ProblemSet = reactive(newProblemSet());

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id == set_id.value) ||
				newProblemSet();
			// need to copy over all fields deeply.
			// Object.assign(set, cloneDeep(s));
			set.set_id = s.set_id;
			set.set_name = s.set_name;
			set.set_visible = s.set_visible;
			set.set_type = s.set_type;
			set.course_id = s.course_id;
			set.dates = cloneDeep(s.dates);
			set.params = cloneDeep(s.params);
		};

		watch(()=>set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set), (new_set, old_set) => {
			console.log('in watch');
			console.log([new_set.set_id, old_set.set_id]);
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
			set_options: [ // probably should be a course_modelValueting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			]
		};
	}
});
</script>

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
import { defineComponent, toRefs, ref, Ref, watch } from 'vue';
import { cloneDeep } from 'lodash-es';

import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { ProblemSet } from 'src/store/models';

export default defineComponent({
	components: { DateTimeInput },
	name: 'Quiz',
	props: {
		modelValue: Object
	},
	setup(props) {
		const s = props.modelValue as ProblemSet;
		const set: Ref<ProblemSet> = ref(cloneDeep(s));

		const { modelValue } = toRefs(props);

		watch(() => modelValue.value,
			() => {
				console.log('modelValue changed');
			}
		);

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

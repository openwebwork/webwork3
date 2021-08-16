<template>
	<table id="modelValuetable">
		<tr>
			<td class="header">Set Name</td>
			<td><q-input v-model="modelValue.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="modelValue.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="modelValue.set_visible" /></td>
		</tr>
		<tr>
			<td class="header">Open Date</td>
			<td><date-time-input v-model="modelValue.dates.open" /></td>
		</tr>
		<tr>
			<td class="header">Due Date</td>
			<td><date-time-input v-model="modelValue.dates.due" /></td>
		</tr>
		<tr>
			<td class="header">Answer Date</td>
			<td><date-time-input v-model="modelValue.dates.answer" /></td>
		</tr>
	</table>
</template>

<script lang="ts">
import { defineComponent, toRefs, watch } from 'vue';
// import { cloneDeep } from 'lodash-es';

import DateTimeInput from 'src/components/common/DateTimeInput.vue';
// import { ProblemmodelValue } from 'src/store/models';

export default defineComponent({
	components: { DateTimeInput },
	name: 'HomeworkSet',
	props: {
		modelValue: Object
	},
	setup(props) {
		const { modelValue } = toRefs(props);

		watch(() => modelValue.value,
			() => {
				console.log('modelValue changed');
			}
		);

		return {
			modelValue,
			set_options: [ // probably should be a course_modelValueting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			]
		};
	}
});
</script>

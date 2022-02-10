<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.open"
				:validation="checkDates"
			/></td>
	</tr>
	<tr v-if="enable_reduced_scoring">
		<td class="header">Reduced Scoring Date</td>
		<td>
			<date-time-input
			v-model="hw_dates.reduced_scoring"
			:validation="checkDates"
			/>
		</td>
	</tr>
	<tr>
		<td class="header">Due Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.due"
				:validation="checkDates"
			/></td>
	</tr>
	<tr>
		<td class="header">Answer Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.answer"
				:validation="checkDates"
			/></td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import type { PropType } from 'vue';
import { checkHWDates } from 'src/common/views';
import { HomeworkSetDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'components/common/DateTimeInput.vue';

export default defineComponent({
	name: 'HomeworkDates',
	props: {
		dates: {
			type: Object as PropType<HomeworkSetDates>,
			required: true
		},
		reduced_scoring: {
			type: Boolean
		}
	},
	components: {
		DateTimeInput
	},
	emits: ['updateDates'],
	setup(props, { emit }) {
		const hw_dates = ref<HomeworkSetDates>(props.dates.clone());
		if (!hw_dates.value.reduced_scoring) {
			hw_dates.value.reduced_scoring = hw_dates.value.due;
		}

		watch(() => hw_dates.value, () => {
			emit('updateDates', hw_dates.value);
		}, { deep: true });

		return {
			hw_dates,
			enable_reduced_scoring: computed(() => props.reduced_scoring),
			checkDates: [
				// Not sure why need to cast this?
				() => checkHWDates(hw_dates.value as HomeworkSetDates, props.reduced_scoring)
			]
		};
	}

});
</script>

<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.open"
				:errorMessage="error_message"
			/></td>
	</tr>
	<tr v-if="enable_reduced_scoring">
		<td class="header">Reduced Scoring Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.reduced_scoring"
				:errorMessage="error_message"
			/>
		</td>
	</tr>
	<tr>
		<td class="header">Due Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.due"
				:errorMessage="error_message"
			/></td>
	</tr>
	<tr>
		<td class="header">Answer Date</td>
		<td>
			<date-time-input
				v-model="hw_dates.answer"
				:errorMessage="error_message"
			/></td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import type { PropType } from 'vue';
import { HomeworkSetDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'components/common/DateTimeInput.vue';
import { logger } from 'src/boot/logger';

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
		const error_message = ref<string>('');

		watch(() => props.dates, (new_dates, old_dates) => {
			logger.debug('[HomeworkDates] parent has changed the homework set dates.');
			logger.debug(`---old: ${JSON.stringify(old_dates)}`);
			logger.debug(`---new: ${JSON.stringify(new_dates)}`);
			hw_dates.value = props.dates.clone();
		});

		watch(() => hw_dates.value, (new_dates, old_dates) => {
			logger.debug('[HomeworkDates] detected mutation in hw_dates...');

			// avoid reactive loop
			if (!props.reduced_scoring && hw_dates.value.reduced_scoring !== hw_dates.value.due) {
				hw_dates.value.reduced_scoring = hw_dates.value.due;
			}

			const dates_are_valid = hw_dates.value.isValid({ enable_reduced_scoring: props.reduced_scoring });
			const is_updated = JSON.stringify(old_dates) !== JSON.stringify(new_dates);
			if (dates_are_valid && is_updated) {
				logger.debug('[HomeworkDates] mutation confirmed + dates are valid -> telling parent.');
				error_message.value = '';
				emit('updateDates', hw_dates.value);
			} else {
				if (!dates_are_valid) error_message.value = 'Dates must be in order.';
				logger.debug(error_message.value || 'Nothing changed. We must be changing between hw sets...');
			};
		}, { deep: true });

		return {
			hw_dates,
			enable_reduced_scoring: computed(() => props.reduced_scoring),
			error_message,
		};
	}

});
</script>

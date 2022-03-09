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
			if (JSON.stringify(old_dates) === JSON.stringify(new_dates)) {
				logger.debug('--- nevermind, this is fallout from the changes we just reported.');
			} else {
				hw_dates.value = props.dates.clone();
			}
		});

		watch(() => hw_dates.value, () => {
			logger.debug('[HomeworkDates] detected mutation in hw_dates...');

			// avoid reactive loop
			if (!props.reduced_scoring && hw_dates.value.reduced_scoring !== hw_dates.value.due) {
				hw_dates.value.reduced_scoring = hw_dates.value.due;
			}

			if (hw_dates.value.isValid({ enable_reduced_scoring: props.reduced_scoring })) {
				logger.debug('[HomeworkDates] dates are valid -> telling parent & clearing error message.');
				error_message.value = '';
				emit('updateDates', hw_dates.value);
			} else {
				error_message.value = 'Dates must be in order.';
				logger.debug(error_message.value);
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

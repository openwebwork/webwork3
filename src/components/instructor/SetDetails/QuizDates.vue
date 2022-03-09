<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.open"
				:errorMessage="error_message"
			/></td>
	</tr>
	<tr>
		<td class="header">Due Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.due"
				:errorMessage="error_message"
			/></td>
	</tr>
	<tr>
		<td class="header">Answer Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.answer"
				:errorMessage="error_message"
			/></td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';
import type { PropType } from 'vue';
import { QuizDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { logger } from 'src/boot/logger';

export default defineComponent({
	name: 'QuizDates',
	props: {
		dates: {
			type: Object as PropType<QuizDates>,
			required: true
		}
	},
	components: {
		DateTimeInput
	},
	emits: ['updateDates'],
	setup(props, { emit }) {
		const quiz_dates = ref<QuizDates>(props.dates.clone());
		const error_message = ref<string>('');

		watch(() => props.dates, (new_dates, old_dates) => {
			logger.debug('[QuizDates] parent has changed the quiz set.');
			logger.debug(`---old: ${JSON.stringify(old_dates)}`);
			logger.debug(`---new: ${JSON.stringify(new_dates)}`);
			quiz_dates.value = props.dates.clone();
		});

		watch(() => quiz_dates.value, (new_dates, old_dates) => {
			logger.debug('[QuizDates] detected mutation in quiz_dates...');

			const dates_are_valid = quiz_dates.value.isValid();
			const is_updated = JSON.stringify(old_dates) !== JSON.stringify(new_dates);
			if (dates_are_valid && is_updated) {
				logger.debug('[QuizDates] mutation confirmed + dates are valid -> telling parent.');
				error_message.value = '';
				emit('updateDates', quiz_dates.value);
			} else {
				if (!dates_are_valid) error_message.value = 'Dates must be in order.';
				logger.debug(error_message.value || 'Nothing changed. We must be changing between quiz sets...');
			};
		}, { deep: true });

		return {
			quiz_dates,
			error_message,
		};
	}

});
</script>

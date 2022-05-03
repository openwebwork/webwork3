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

<script setup lang="ts">
import { ref, watch, defineEmits, defineProps } from 'vue';
import type { PropType } from 'vue';
import { QuizDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'src/components/common/DateTimeInput.vue';
import { logger } from 'src/boot/logger';

const props = defineProps({
	dates: {
		type: Object as PropType<QuizDates>,
		required: true
	}
});

const emit = defineEmits(['updateDates', 'validDates']);

const quiz_dates = ref<QuizDates>(props.dates.clone());
const error_message = ref<string>('');

watch(() => props.dates, (new_dates, old_dates) => {
	logger.debug('[QuizDates] parent has changed the quiz set.');
	if (JSON.stringify(old_dates) === JSON.stringify(new_dates)) {
		logger.debug('--- nevermind, this is fallout from the changes we just reported.');
	} else {
		quiz_dates.value = props.dates.clone();
	}
});

watch(() => quiz_dates.value, () => {
	logger.debug('[QuizDates] detected mutation in quiz_dates...');

	if (quiz_dates.value.isValid()) {
		logger.debug('[QuizDates] dates are valid -> telling parent & clearing error message.');
		error_message.value = '';
		emit('validDates', true);
		emit('updateDates', quiz_dates.value);
	} else {
		emit('validDates', false);
		error_message.value = 'Dates must be in order.';
		logger.debug(error_message.value);
	};
}, { deep: true });
</script>

<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="review_dates.open"
				:errorMessage="error_message"
			/>
		</td>
	</tr>
	<tr>
		<td class="header">Closed Date</td>
		<td>
			<date-time-input
				v-model="review_dates.closed"
				:errorMessage="error_message"
			/>
		</td>
	</tr>
</template>

<script setup lang="ts">
import { ref, watch, defineEmits, defineProps } from 'vue';
import type { PropType } from 'vue';
import { ReviewSetDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'components/common/DateTimeInput.vue';
import { logger } from 'src/boot/logger';

const props = defineProps({
	dates: {
		type: Object as PropType<ReviewSetDates>,
		required: true
	}
});

const emit = defineEmits(['updateDates', 'validDates']);

const review_dates = ref<ReviewSetDates>(props.dates.clone());
const error_message = ref<string>('');

watch(() => props.dates, (new_dates, old_dates) => {
	logger.debug('[ReviewDates] parent has changed the review set.');
	if (JSON.stringify(old_dates) === JSON.stringify(new_dates)) {
		logger.debug('--- nevermind, this is fallout from the changes we just reported.');
	} else {
		review_dates.value = props.dates.clone();
	}
});

watch(() => review_dates.value, () => {
	logger.debug('[ReviewDates] detected mutation in review_dates...');

	if (review_dates.value.isValid()) {
		logger.debug('[ReviewDates] dates are valid -> telling parent & clearing error message.');
		error_message.value = '';
		emit('validDates', true);
		emit('updateDates', review_dates.value);
	} else {
		error_message.value = 'Dates must be in order.';
		emit('validDates', false);
		logger.debug(error_message.value);
	};
}, { deep: true });
</script>

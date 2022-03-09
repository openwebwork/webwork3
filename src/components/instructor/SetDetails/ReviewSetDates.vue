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

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';
import type { PropType } from 'vue';
import { ReviewSetDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'components/common/DateTimeInput.vue';
import { logger } from 'src/boot/logger';

export default defineComponent({
	name: 'ReviewSetDates',
	props: {
		dates: {
			type: Object as PropType<ReviewSetDates>,
			required: true
		}
	},
	components: {
		DateTimeInput
	},
	emits: ['updateDates'],
	setup(props, { emit }) {
		const review_dates = ref<ReviewSetDates>(props.dates.clone());
		const error_message = ref<string>('');

		watch(() => props.dates, (new_dates, old_dates) => {
			logger.debug('[ReviewDates] parent has changed the review set.');
			logger.debug(`---old: ${JSON.stringify(old_dates)}`);
			logger.debug(`---new: ${JSON.stringify(new_dates)}`);
			review_dates.value = props.dates.clone();
		});

		watch(() => review_dates.value, (new_dates, old_dates) => {
			logger.debug('[ReviewDates] detected mutation in review_dates...');

			const dates_are_valid = review_dates.value.isValid();
			const is_updated = JSON.stringify(old_dates) !== JSON.stringify(new_dates);
			if (dates_are_valid && is_updated) {
				logger.debug('[ReviewDates] mutation confirmed + dates are valid -> telling parent.');
				error_message.value = '';
				emit('updateDates', review_dates.value);
			} else {
				if (!dates_are_valid) error_message.value = 'Dates must be in order.';
				logger.debug(error_message.value || 'Nothing changed. We must be changing between review sets...');
			};
		}, { deep: true });

		return {
			review_dates,
			error_message,
		};
	}

});
</script>

<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="review_set_dates.open"
				:validation="checkDates"
			/>
		</td>
	</tr>
	<tr>
		<td class="header">Closed Date</td>
		<td>
			<date-time-input
				v-model="review_set_dates.closed"
				:validation="checkDates"
			/>
		</td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import type { PropType } from 'vue';
import { checkReviewSetDates } from 'src/common';
import { ReviewSetDates } from 'src/store/models/problem_sets';
import DateTimeInput from 'components/common/DateTimeInput.vue';

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
	setup(props){
		const review_set_dates = ref<ReviewSetDates>(props.dates);

		return {
			review_set_dates,
			checkDates: [
				() => checkReviewSetDates(review_set_dates.value)
			]
		};
	}

});
</script>

<template>
<!-- Note: this is expected to be inside a plain table -->
	<tr>
		<td class="header">Open Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.open"
				:validation="checkDates"
			/></td>
	</tr>
	<tr>
		<td class="header">Due Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.due"
				:validation="checkDates"
			/></td>
	</tr>
	<tr>
		<td class="header">Answer Date</td>
		<td>
			<date-time-input
				v-model="quiz_dates.answer"
				:validation="checkDates"
			/></td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import type { PropType } from 'vue';
import { checkQuizDates } from 'src/common/views';
import { QuizDates } from 'src/common/models/problem_sets';
import DateTimeInput from 'src/components/common/DateTimeInput.vue';

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
	setup(props) {
		const quiz_dates = ref<QuizDates>(props.dates);

		return {
			quiz_dates,
			checkDates: [() => checkQuizDates(quiz_dates.value)]
		};
	}

});
</script>

<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><input-with-blur v-model="quiz.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="quiz.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="quiz.set_visible" /></td>
		</tr>
		<quiz-dates-input v-if="set"
			:dates="quiz.set_dates"
			@update-dates="updateDates"
			/>
		<tr>
			<td class="header">Timed</td>
			<td><q-toggle v-model="quiz.set_params.timed" /></td>
		</tr>
		<tr v-if="quiz.set_params.timed">
			<td class="header">Duration of Quiz</td>
			<td><q-input v-model="quiz.set_params.quiz_duration" :rules="quizDuration" debounce="500"/> </td>
		</tr>
	</table>
</template>

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';

import QuizDatesInput from './QuizDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { Quiz, QuizDates } from 'src/common/models/problem_sets';
import { problem_set_type_options } from 'src/common/views';

export default defineComponent({
	components: {
		QuizDatesInput,
		InputWithBlur
	},
	props: {
		set: {
			type: Quiz,
			required: true
		}
	},
	name: 'Quiz',
	emits: ['updateSet'],
	setup(props, { emit }) {
		const quiz = ref<Quiz>(props.set.clone());

		watch(() => props.set, () => {
			quiz.value = props.set.clone();
		}, { deep: true });

		watch(() => quiz.value.clone(), (new_quiz, old_quiz) => {
			if (JSON.stringify(new_quiz) !== JSON.stringify(old_quiz)) {
				emit('updateSet', quiz.value);
			}
		},
		{ deep: true });

		return {
			set_options: problem_set_type_options,
			quiz,
			updateDates: (dates: QuizDates) => {
				quiz.value.set_dates.set(dates.toObject());
			},
			quizDuration: [
				(val: string) => /^\d+\s(secs?|mins?)$/.test(val) || // add this RegExp elsewhere
				'The duration of the quiz must be a valid length of time'
			]
		};
	}
});
</script>

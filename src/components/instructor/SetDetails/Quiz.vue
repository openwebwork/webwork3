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
		<quiz-dates v-if="set"
			:dates="quiz.set_dates"
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
import { defineComponent, ref, watch, computed } from 'vue';

import QuizDates from './QuizDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { Quiz } from 'src/common/models/problem_sets';
import { useRoute } from 'vue-router';
import { parseRouteSetID } from 'src/router/utils';

export default defineComponent({
	components: {
		QuizDates,
		InputWithBlur
	},
	props: {
		set: {
			type: Quiz,
			required: true
		}
	},
	name: 'Quiz',
	setup(props, { emit }) {
		const route = useRoute();

		const set_id = computed(() => parseRouteSetID(route));
		const quiz = ref<Quiz>(props.set.clone());

		watch(() => quiz.value.clone(), () => {
			emit('updateSet', quiz.value);
		},
		{ deep: true });

		return {
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
			set_id,
			quiz,
			quizDuration: [
				(val: string) => /^\d+\s(secs?|mins?)$/.test(val) || // add this RegExp elsewhere
				'The duration of the quiz must be a valid length of time'
			]
		};
	}
});
</script>

<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><input-with-blur v-model="quiz.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td>
				<q-select
					map-options
					:options="set_options"
					v-model="set_type"
					@update:model-value="$emit('changeSetType', set_type)"
				/>
			</td>
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
			<td class="header">Duration of Quiz (HH:MM:SS)</td>
			<td><q-input v-model="quiz_duration" mask="##:##:##" debounce="1500"/> </td>
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
		},
		reset_set_type: {
			type: String,
			required: false
		}
	},
	name: 'Quiz',
	emits: ['updateSet', 'changeSetType'],
	setup(props, { emit }) {
		const quiz = ref<Quiz>(props.set.clone());
		const set_type = ref<string | undefined>(props.set.set_type);
		const quiz_duration = ref<string>('');

		// If a set type changed is cancelled this resets to the original.
		watch(() => props.reset_set_type, () => {
			set_type.value = props.reset_set_type;
		});

		watch(() => props.set, () => {
			quiz.value = props.set.clone();
		}, { deep: true });

		watch(() => quiz.value.clone(), (new_quiz, old_quiz) => {
			if (JSON.stringify(new_quiz) !== JSON.stringify(old_quiz)) {
				emit('updateSet', quiz.value);
			}
		},
		{ deep: true });

		// parse the set_params.quiz_duration value

		const quizDurationToString = (value: number) => {
			const secs = value % 60;
			const hrs = Math.floor(value / 3600);
			const mins = Math.floor((value - 3600 * hrs) / 60);
			return hrs < 10 ? `0${hrs}:${mins}:${secs}` : `${hrs}:${mins}:${secs}`;
		};
		quiz_duration.value = quizDurationToString(quiz.value.set_params.quiz_duration ?? 0);

		watch(() => quiz.value.set_params.quiz_duration, () => {
			quiz_duration.value = quizDurationToString(quiz.value.set_params.quiz_duration);
		});

		const quizDurationToValue = (duration: string) => {
			console.log(duration);
			const vals = /(\d?\d):(\d\d):(\d\d)/.exec(duration);
			return vals?.length == 4 ? parseInt(vals[1]) * 60 * 60 + parseInt(vals[2]) * 60 + parseInt(vals[3]) : 0;
		};

		watch(() => quiz_duration.value, () => {
			quiz.value.set_params.quiz_duration = quizDurationToValue(quiz_duration.value);
			console.log(quizDurationToValue(quiz_duration.value));
		});

		return {
			set_type,
			set_options: problem_set_type_options,
			quiz,
			updateDates: (dates: QuizDates) => {
				quiz.value.set_dates.set(dates.toObject());
			},
			quiz_duration
		};
	}
});
</script>

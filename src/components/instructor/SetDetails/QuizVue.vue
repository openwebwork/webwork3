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
import { logger } from 'boot/logger';

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

		watch(() => props.set, (new_set, old_set) => {
			logger.debug(`[Quiz] parent changed homework set from: ${old_set.set_name} to ${new_set.set_name}`);
			quiz.value = props.set.clone();
		});

		watch(() => quiz.value, () => {
			logger.debug('[Quiz] detected mutation in homework_set...');
			emit('updateSet', quiz.value);
		},
		{ deep: true });

		// parse the set_params.quiz_duration value

		const quizDurationToString = (value: number) => {
			const secs = value % 60;
			const hrs = Math.floor(value / 3600);
			const mins = Math.floor((value - 3600 * hrs) / 60);
			const hr_str = hrs < 10 ? `0${hrs}` : `${hrs}`;
			const min_str = mins < 10 ? `0${mins}` : `${mins}`;
			const sec_str = secs < 10 ? `0${secs}` : `${secs}`;
			return `${hr_str}:${min_str}:${sec_str}`;
		};
		quiz_duration.value = quizDurationToString(quiz.value.set_params.quiz_duration ?? 0);

		watch(() => quiz.value.set_params.quiz_duration, () => {
			quiz_duration.value = quizDurationToString(quiz.value.set_params.quiz_duration);
		});

		const quizDurationToValue = (duration: string) => {
			const vals = /(\d?\d):(\d\d):(\d\d)/.exec(duration);
			return vals?.length == 4 ? parseInt(vals[1]) * 60 * 60 + parseInt(vals[2]) * 60 + parseInt(vals[3]) : 0;
		};

		watch(() => quiz_duration.value, () => {
			quiz.value.set_params.quiz_duration = quizDurationToValue(quiz_duration.value);
		});

		return {
			set_type,
			set_options: problem_set_type_options,
			quiz,
			updateDates: (dates: QuizDates) => {
				logger.debug('[Quiz/updateDates] setting dates on quiz.');
				quiz.value.set_dates.set(dates.toObject());
			},
			quiz_duration
		};
	}
});
</script>

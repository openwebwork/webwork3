<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><q-input v-model="set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="set.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="set.set_visible" /></td>
		</tr>
		<quiz-dates v-if="set"
			:dates="set.set_dates"
			/>
		<tr>
			<td class="header">Timed</td>
			<td><q-toggle v-model="set.set_params.timed" /></td>
		</tr>
		<tr v-if="set.set_params.timed">
			<td class="header">Duration of Quiz</td>
			<td><q-input v-model="set.set_params.quiz_duration" :rules="quizDuration" debounce="500"/> </td>
		</tr>
	</table>
</template>

<script lang="ts">
import { defineComponent, ref, watch, toRefs } from 'vue';
import { useQuasar } from 'quasar';
import { cloneDeep, pick } from 'lodash-es';

import QuizDates from './QuizDates.vue';
import { Quiz } from 'src/store/models/problem_sets';
import { useStore } from 'src/store';

export default defineComponent({
	components: { QuizDates },
	name: 'Quiz',
	props: {
		set_id: Number
	},
	setup(props) {
		const store = useStore();
		const $q = useQuasar();

		const { set_id } = toRefs(props);

		const set = ref<Quiz>(new Quiz());

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id == set_id.value) ||
				new Quiz();
			set.value = cloneDeep(s as Quiz);
		};

		watch(() => set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set.value), (new_set, old_set) => {
			if (new_set.set_id === old_set.set_id) {
				// cloning above in the watch statement changes that it is a Quiz
				const _set = new Quiz(pick(new_set, Quiz.ALL_FIELDS));
				void store.dispatch('problem_sets/updateSet', _set);
				$q.notify({
					message: `The problem set '${new_set.set_name ?? ''}' was successfully updated.`,
					color: 'green'
				});
			}
		},
		{ deep: true });

		return {
			set,
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
			checkDates: [
				() => {
					const d = set.value.set_dates;
					return d.open <= d.due && d.due <= d.answer || 'The dates must be in order';
				}
			],
			quizDuration: [
				(val: string) => /^\d+\s(secs?|mins?)$/.test(val) || // add this RegExp elsewhere
				'The duration of the quiz must be a valid length of time'
			]
		};
	}
});
</script>

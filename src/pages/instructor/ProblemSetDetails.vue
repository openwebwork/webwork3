<template>
	<q-page class="q-ma-p-lg">
		<homework-set-view
			:set="problem_set"
			:reset_set_type="reset_set_type"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-if="problem_set.set_type==='HW'" />
		<quiz-view
			:set="problem_set"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-else-if="problem_set.set_type==='QUIZ'" />
		<review-set-view
			:set="problem_set"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-else-if="problem_set.set_type==='REVIEW'" />
	</q-page>
	<q-dialog v-model="change_set_type_dialog" persistent>
      <q-card>
        <q-card-section class="row items-center">
          <span class="q-ml-sm">You have requested that this set be converted from a
						{{ problem_set.set_type }} to a {{ new_set_type.label }}.  You may lose
						information that the old set has that the new set does not have capabilities
						of. Please select "Ok" or "Cancel".
					</span>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="Cancel" color="primary" v-close-popup @click="cancelChangeSetType"/>
          <q-btn flat label="OK" color="primary" v-close-popup @click="changeSetType"/>
        </q-card-actions>
      </q-card>
    </q-dialog>
</template>

<script lang="ts">
import { defineComponent, computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useQuasar } from 'quasar';
import { logger } from 'boot/logger';

import { useStore } from 'src/store';
import { parseRouteSetID } from 'src/router/utils';
import { ProblemSet, HomeworkSet, ReviewSet, Quiz } from 'src/common/models/problem_sets';
import HomeworkSetView from 'src/components/instructor/SetDetails/HomeworkSet.vue';
import QuizView from 'src/components/instructor/SetDetails/Quiz.vue';
import ReviewSetView from 'src/components/instructor/SetDetails/ReviewSet.vue';

export default defineComponent({
	name: 'ProblemSetDetails',
	components: {
		HomeworkSetView,
		QuizView,
		ReviewSetView
	},
	setup() {
		const route = useRoute();
		const store = useStore();
		const $q = useQuasar();

		const change_set_type_dialog = ref<boolean>(false);
		const new_set_type = ref<{value?: string, label?: string}>({});
		// Used to reset the set type in the children views if the set type change is cancelled.
		// This seems like overkill--perhaps a better way.
		const reset_set_type = ref<string>('');
		const set_id = computed(() => parseRouteSetID(route));
		const problem_set = computed(() => store.state.problem_sets.problem_sets
			.find((_set) => _set.set_id === set_id.value) ?? new ProblemSet());

		const updateSet =  (set: ProblemSet) => {
			// if the entire set just changed, don't update.
			if (problem_set.value.set_id === set.set_id) {
				void store.dispatch('problem_sets/updateSet', set);
				const msg = `The problem set '${set.set_name}' was successfully updated.`;
				logger.debug(`[ProblemSetDetails]: ${msg}`);
				$q.notify({
					message: msg,
					color: 'green'
				});
			}
		};

		return {
			set_id,
			problem_set,
			change_set_type_dialog,
			new_set_type,
			reset_set_type,
			updateSet,
			requestChangeSetType: (set_type: {value: string, label: string}) => {
				change_set_type_dialog.value = true;
				new_set_type.value = set_type;
				// This is needed if the set type change is cancelled.
				reset_set_type.value = '';
				logger.debug('ProblemSetDetails: Requesting a set type change');
			},
			cancelChangeSetType: () => {
				// If the set type change is cancel, reset the set type in any child of this.
				reset_set_type.value = problem_set.value.set_type;
			},
			// Change the type of the set.  Since the set_params don't really overlap (right now)
			// this is just adjusting dates.
			changeSetType: () => {
				const problem_set_params = problem_set.value.toObject();
				delete problem_set_params.set_params;
				delete problem_set_params.set_dates;

				// Try to best keep the dates consistent.
				if (new_set_type.value.value === 'QUIZ') {
					const new_quiz = new Quiz(problem_set_params);
					if (problem_set.value instanceof HomeworkSet) {
						new_quiz.set_dates.set({
							open: problem_set.value.set_dates.open,
							due: problem_set.value.set_dates.due,
							answer: problem_set.value.set_dates.answer
						});
					} else if (problem_set.value instanceof ReviewSet) {
						new_quiz.set_dates.set({
							open: problem_set.value.set_dates.open,
							due: problem_set.value.set_dates.closed,
							answer: problem_set.value.set_dates.closed
						});
					}
					updateSet(new_quiz);
				} else if (new_set_type.value.value === 'REVIEW') {
					const new_review_set = new ReviewSet(problem_set_params);
					if (problem_set.value instanceof HomeworkSet || problem_set.value instanceof Quiz) {
						new_review_set.set_dates.set({
							open: problem_set.value.set_dates.open,
							closed: problem_set.value.set_dates.due,
						});
					}
					updateSet(new_review_set);
				} else if (new_set_type.value.value === 'HW') {
					const new_hw_set = new HomeworkSet(problem_set_params);
					if (problem_set.value instanceof ReviewSet) {
						new_hw_set.set_dates.set({
							open: problem_set.value.set_dates.open,
							reduced_scoring: problem_set.value.set_dates.closed,
							due: problem_set.value.set_dates.closed,
							answer: problem_set.value.set_dates.closed
						});
					} else if (problem_set.value instanceof Quiz) {
						new_hw_set.set_dates.set({
							open: problem_set.value.set_dates.open,
							reduced_scoring: problem_set.value.set_dates.due,
							due: problem_set.value.set_dates.due,
							answer: problem_set.value.set_dates.answer
						});
					}
					updateSet(new_hw_set);
				} else {
					logger.debug('ProblemSetDetails: oops, set type ' +
						`${new_set_type.value.value ?? 'UNKNOWN'} not defined.`);
					return;
				}

			}
		};
	}
});
</script>

<style type="text/css">
.header {
	font-weight: bold;
	font-size: 120%;
	width: 200px;
}

table#settable {
	margin: 10px;
}
</style>

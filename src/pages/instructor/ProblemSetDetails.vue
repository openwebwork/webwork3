<template>
	<q-page class="q-ma-p-lg">
		<!-- The key attribute needs to be unique on the component so prefix it. -->
		<homework-set-vue
			:set="(problem_set as HomeworkSet)"
			:key="'HW' + set_id"
			:reset_set_type="reset_set_type"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-if="problem_set?.set_type==='HW'" />
		<quiz-vue
			:set="(problem_set as Quiz)"
			:key="'QUIZ' + set_id"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-else-if="problem_set?.set_type==='QUIZ'" />
		<review-set-vue
			:set="(problem_set as ReviewSet)"
			:key="'REVIEW_SET' + set_id"
			@update-set="updateSet"
			@change-set-type="requestChangeSetType"
			v-else-if="problem_set?.set_type==='REVIEW'" />
	</q-page>
	<q-dialog v-model="change_set_type_dialog" persistent>
		<q-card>
			<q-card-section class="row items-center">
				<span class="q-ml-sm">You have requested that this set be converted from a
					{{ problem_set?.set_type }} to a {{ new_set_type.label }}.  You may lose
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

import { useProblemSetStore } from 'src/stores/problem_sets';
import { parseRouteSetID } from 'src/router/utils';
import { ProblemSet, ProblemSetType, convertSet, HomeworkSet, ReviewSet, Quiz
} from 'src/common/models/problem_sets';
import HomeworkSetVue from 'src/components/instructor/SetDetails/HomeworkSetVue.vue';
import QuizVue from 'src/components/instructor/SetDetails/QuizVue.vue';
import ReviewSetVue from 'src/components/instructor/SetDetails/ReviewSetVue.vue';
import { ResponseError } from 'src/common/api-requests/errors';

export default defineComponent({
	name: 'ProblemSetDetails',
	components: {
		HomeworkSetVue,
		QuizVue,
		ReviewSetVue
	},
	setup() {
		const route = useRoute();
		const problem_sets = useProblemSetStore();
		const $q = useQuasar();

		const change_set_type_dialog = ref<boolean>(false);
		const new_set_type = ref<{value?: ProblemSetType, label?: string}>({});
		// Used to reset the set type in the children views if the set type change is cancelled.
		// This seems like overkill--perhaps a better way.
		const reset_set_type = ref<string>('');
		const set_id = computed(() => parseRouteSetID(route));
		const problem_set = computed(() => problem_sets.problem_sets
			.find((_set) => _set.set_id === set_id.value));
		// avoid a race condition while updating a set
		const updatePending = ref<boolean>(false);

		const updateSet = async (set: ProblemSet) => {
			logger.debug('[ProblemSetDetails] updating set');
			if (updatePending.value) {
				logger.debug('--- but there is already an update pending... race condition?');
				return;
			}
			// if the entire set just changed, don't update.
			if (problem_set.value && problem_set.value.set_id === set.set_id) {
				updatePending.value = true;
				try {
					const updated_set = await problem_sets.updateSet(set);
					updatePending.value = false;
					const message = `The problem set with name ${updated_set?.set_name
						?? 'UNKNOWN'} was updated successfully.`;
					logger.debug(`[ProblemSetDetails/updateSet]: ${message}`);
					$q.notify({
						message,
						color: 'green'
					});
				} catch (err) {
					const error = err as ResponseError;
					$q.notify({
						message: error.message,
						color: 'red'
					});
				}
			}
		};

		const requestChangeSetType = (set_type: {value: ProblemSetType, label: string}) => {
			logger.debug('ProblemSetDetails: Requesting a set type change');
			change_set_type_dialog.value = true;
			new_set_type.value = set_type;
			// This is needed if the set type change is cancelled.
			reset_set_type.value = '';
		};

		const cancelChangeSetType = () => {
			// If the set type change is cancelled, reset the set type in any child of this.
			if (problem_set.value) reset_set_type.value = problem_set.value.set_type;
		};

		const changeSetType = () => {
			logger.debug('[ProblemSetDetails/changeSetType]');
			if (problem_set.value && new_set_type.value.value) {
				const updated_set = convertSet((problem_set.value as ProblemSet), new_set_type.value.value);
				void updateSet(updated_set);
			} else {
				logger.error('[changeSetType] missing either problem_set or new_set_type?! TSNH');
			}
		};

		return {
			set_id,
			problem_set,
			change_set_type_dialog,
			new_set_type,
			reset_set_type,
			updateSet,
			requestChangeSetType,
			cancelChangeSetType,
			changeSetType,
			HomeworkSet,
			Quiz,
			ReviewSet
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

<template>
	<q-page class="q-ma-p-lg">
		<homework-set
			:set="problem_set"
			@update-set="updateSet"
			v-if="problem_set.set_type==='HW'" />
		<quiz
			:set="problem_set"
			@update-set="updateSet"
			v-else-if="problem_set.set_type==='QUIZ'" />
		<review-set
			:set="problem_set"
			@update-set="updateSet"
			v-else-if="problem_set.set_type==='REVIEW'" />
	</q-page>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useQuasar } from 'quasar';

import { useStore } from 'src/store';
import { parseRouteSetID } from 'src/router/utils';
import { ProblemSet } from 'src/common/models/problem_sets';
import HomeworkSet from 'src/components/instructor/SetDetails/HomeworkSet.vue';
import Quiz from 'src/components/instructor/SetDetails/Quiz.vue';
import ReviewSet from 'src/components/instructor/SetDetails/ReviewSet.vue';

export default defineComponent({
	name: 'ProblemSetDetails',
	components: {
		HomeworkSet,
		Quiz,
		ReviewSet
	},
	setup() {
		const route = useRoute();
		const store = useStore();
		const $q = useQuasar();

		const set_id = computed(() => parseRouteSetID(route));
		const problem_set = computed(() => store.state.problem_sets.problem_sets
			.find((_set) => _set.set_id === set_id.value) ?? new ProblemSet());

		return {
			set_id,
			problem_set,
			updateSet: (set: ProblemSet) => {
				// if the entire set just changed, don't update.
				if (problem_set.value.set_id === set.set_id) {
					void store.dispatch('problem_sets/updateSet', set);
					$q.notify({
						message: `The problem set '${set.set_name}' was successfully updated.`,
						color: 'green'
					});
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

<template>
	<q-page class="q-ma-p-lg">
		<homework-set :set_id="set_id" v-if="set_type==='HW'" />
		<quiz :set_id="set_id" v-else-if="set_type==='QUIZ'" />
		<review-set :set_id="set_id" v-else-if="set_type==='REVIEW'" />
	</q-page>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRoute } from 'vue-router';

import { useStore } from 'src/store';
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
		const parseSetId = () => {
			return Array.isArray(route.params.set_id)
				? parseInt(route.params.set_id[0])
				: parseInt(route.params.set_id);
		};

		return {
			set_id: computed(() => parseSetId()),
			set_type: computed(() => {
				const _set_id = parseSetId();
				const s = store.state.problem_sets.problem_sets.find((_set: ProblemSet) => _set.set_id == _set_id) ||
					new ProblemSet();
				return s.set_type;
			})
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

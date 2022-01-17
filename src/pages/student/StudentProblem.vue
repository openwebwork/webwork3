<template>
	<problem v-if="user_problem"
		:problem="user_problem"
	/>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'src/store';

import { parseNumericRouteParam } from 'src/common';

import Problem from 'src/components/common/Problem.vue';
import { parse } from 'papaparse';

export default defineComponent({
	name: 'StudentProblem',
	components: {
		Problem
	},
	setup() {
		const route = useRoute();
		const store = useStore();

		const set_id = computed(() => parseNumericRouteParam(route.params.set_id));
		const problem_id = computed(() => parseNumericRouteParam(route.params.problem_id));

		return {
			set_id,
			problem_id,
			user_set: computed(
				() => store.state.problem_sets.merged_user_sets.find(set => set.set_id === set_id.value)
			),
			user_problem: computed(
				() => store.state.problem_sets.merged_user_problems.find(
					prob => prob.set_id === set_id.value && prob.problem_id === problem_id.value)
			)
		};
	}
});
</script>

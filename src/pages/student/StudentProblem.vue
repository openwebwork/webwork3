<template>
	<problem v-if="user_problem"
		:problem="user_problem"
	/>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRoute } from 'vue-router';

import { parseNumericRouteParam } from 'src/common/views';

import Problem from 'src/components/common/Problem.vue';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';

export default defineComponent({
	name: 'StudentProblem',
	components: {
		Problem
	},
	setup() {
		const route = useRoute();
		const problem_sets = useProblemSetStore();
		const set_problem_store = useSetProblemStore();

		const set_id = computed(() => parseNumericRouteParam(route.params.set_id));
		const problem_id = computed(() => parseNumericRouteParam(route.params.problem_id));

		return {
			set_id,
			problem_id,
			user_set: computed(
				() => problem_sets.user_sets.find(set => set.set_id === set_id.value)
			),
			user_problem: computed(
				() => set_problem_store.user_problems.find(
					prob => prob.set_id === set_id.value && prob.problem_id === problem_id.value)
			)
		};
	}
});
</script>

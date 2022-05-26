<template>
	<div v-if="problems.length >0" class="scroll" style="height: 700px">
		<draggable
			class="dragArea list-group w-full"
			handle=".move-handle"
			:list="problems"
			@change="reorderProblems"
		>
			<div v-for="problem in (problems as SetProblem[])" :key="problem.problem_number">
				<problem-vue
					:problem="problem"
					class="q-mb-md"
					@remove-problem="deleteProblem"
				/>
			</div>
		</draggable>
	</div>
	<div class="bg-info" v-else>
		<q-banner dense inline-actions class="text-white bg-info rounded-borders">
		There are no problems associated with this set.  Use the library browser to add problems.
		</q-banner>
	</div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from 'vue';
import { useQuasar } from 'quasar';
import { useRoute } from 'vue-router';
import { VueDraggableNext as draggable } from 'vue-draggable-next';

import { useProblemSetStore } from 'src/stores/problem_sets';

import ProblemVue from 'components/common/Problem.vue';
import { ProblemSet } from 'src/common/models/problem_sets';
import { Problem, SetProblem } from 'src/common/models/problems';
import { ResponseError } from 'src/common/api-requests/interfaces';
import { logger } from 'boot/logger';
import { parseRouteSetID } from 'src/router/utils';
import { useSetProblemStore } from 'src/stores/set_problems';

const $q = useQuasar();
const problem_sets = useProblemSetStore();
const set_problem_store = useSetProblemStore();
const route = useRoute();
// copy of the set_id prop and ensure it is a number
const problems = ref<Array<SetProblem>>([]);
const problem_set = ref<ProblemSet>(new ProblemSet());

const set_id = computed(() => parseRouteSetID(route));

const updateProblemSet = () => {
	problems.value = set_problem_store.set_problems
		.filter(set => set.set_id === set_id.value)
		.sort((prob_a, prob_b) =>
			(prob_a.problem_number ?? 0) - (prob_b.problem_number ?? 0));
	problem_set.value = problem_sets.problem_sets
		.find(set => set.set_id === set_id.value) || new ProblemSet();
	logger.debug(`[SetDetailProblems] populating problems... count:${problems.value.length}`);
};
updateProblemSet();

watch(() => set_id.value, updateProblemSet);

const reorderProblems = async () => {
	const promises: Promise<Problem | undefined>[] = [];
	problems.value.forEach((prob, i) => {
		if (prob.problem_number !== i + 1) {
			promises.push(set_problem_store.updateSetProblem({
				set_id: prob.set_id,
				problem_id: prob.problem_id,
				props: { problem_number: i + 1 }
			}));
		}
	});
	await Promise.all(promises)
		.then(() => {
			$q.notify({
				message: `Reordered problems in set ${problem_set.value.set_name ?? 'UNKNOWN'}.`,
				color: 'green'
			});
		})
		.catch((reason: Error) => {
			$q.notify({
				message: reason.message,
				color: 'red',
			});
		});
	logger.debug(`Reordering the set: ${problem_set.value.set_name ?? 'UNKNOWN'}.`);
	updateProblemSet();
};

const deleteProblem = async (problem: SetProblem) => {
	logger.debug(`[Problem/deleteProblem]: Remove problem ${problem.path()} `
			+ `from set : ${problem_set.value.set_name ?? 'UNKNOWN'}.`);
	try {
		await set_problem_store.deleteSetProblem(problem);
		$q.notify({
			message: `A problem has been removed from set ${problem_set.value.set_name ?? 'UNKNOWN'}`,
			color: 'green'
		});
		updateProblemSet();
	} catch (err) {
		const error = err as ResponseError;
		$q.notify({ message: error.message, color: 'red' });
	}
};
</script>

<template>
	<div v-if="problems.length >0" class="scroll" style="height: 700px">
		<draggable
			class="dragArea list-group w-full"
			handle=".move-handle"
			:list="problems"
			@change="reorderProblems"
		>
			<div v-for="problem in problems" :key="problem.problem_number">
				<problem
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

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';
import { useQuasar } from 'quasar';
import { useStore } from 'src/store';
import { VueDraggableNext } from 'vue-draggable-next';
import Problem from 'components/common/Problem.vue';
import { ProblemSet } from 'src/store/models/problem_sets';
import { SetProblem } from 'src/store/models/problems';
import { ResponseError } from 'src/store/models';
import { logger } from 'boot/logger';

export default defineComponent({
	name: 'SetDetailProblems',
	props: {
		set_id: {
			type: Number,
			default: 0
		}
	},
	components: {
		Problem,
		draggable: VueDraggableNext
	},
	setup(props) {
		const $q = useQuasar();
		const store = useStore();
		// copy of the set_id prop and ensure it is a number
		const problems = ref<Array<SetProblem>>([]);
		const problem_set = ref<ProblemSet>(new ProblemSet());

		const updateProblemSet = () => {
			problems.value = store.state.problem_sets.set_problems.filter(set => set.set_id === props.set_id).concat()
				.sort((prob_a: SetProblem, prob_b: SetProblem) =>
					(prob_a?.problem_number ?? 0) - (prob_b?.problem_number ?? 0));
			problem_set.value = store.state.problem_sets.problem_sets
				.find(set => set.set_id === props.set_id) || new ProblemSet();
			logger.debug(`[SetDetailProblems] populating problems... count:${problems.value.length}`);
		};
		updateProblemSet();

		watch(() => props.set_id, updateProblemSet);

		return {
			problem_set,
			problems,
			reorderProblems: async () => {
				const promises: Array<Promise<void>> = [];
				problems.value.forEach((prob, i) => {
					if (prob.problem_number !== i + 1) {
						promises.push(
							store.dispatch('problem_sets/updateSetProblem',
								{ prob, props: { problem_number: i + 1 } }
							)
						);
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
			},
			deleteProblem: async (problem: SetProblem) => {
				logger.debug(`[Problem/deleteProblem]: Remove problem ${problem.path()} `
					+ `from set : ${problem_set.value.set_name ?? 'UNKNOWN'}.`);
				try {
					await store.dispatch('problem_sets/deleteSetProblem', problem);
					$q.notify({
						message: `A problem has been removed from set ${problem_set.value.set_name ?? 'UNKNOWN'}`,
						color: 'green'
					});
					updateProblemSet();
				} catch (err) {
					const error = err as ResponseError;
					$q.notify({ message: error.message, color: 'red' });
				}
			}
		};
	}

});
</script>

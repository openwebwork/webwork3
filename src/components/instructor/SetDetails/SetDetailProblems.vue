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
import type { Ref } from 'vue';
import { useStore } from '@/store';
import { VueDraggableNext } from 'vue-draggable-next';
import Problem from '@/components/common/Problem.vue';
import { ProblemSet } from '@/store/models/problem_sets';
import { sortBy } from 'lodash-es';
import { SetProblem } from '@/store/models/set_problem';
import { logger } from '@/boot/logger';

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
		const store = useStore();
		// copy of the set_id prop and ensure it is a number
		// const local_set_id = ref(props.set_id);
		const problems: Ref<Array<SetProblem>> = ref([]);
		const problem_set: Ref<ProblemSet> = ref(new ProblemSet());

		const updateProblemSet = () => {
			problems.value = sortBy(store.state.problem_sets.set_problems
				.filter(set => set.set_id === props.set_id), (prob: SetProblem) => prob.problem_number);
			problem_set.value = store.state.problem_sets.problem_sets
				.find(set => set.set_id === props.set_id) || new ProblemSet();
			logger.debug(`[SetDetailProblems] populating problems... count:${problems.value.length}`);
		};
		updateProblemSet();

		watch(() => props.set_id, updateProblemSet);

		return {
			problem_set,
			problems,
			reorderProblems: () => {
				problems.value.forEach((prob, i) => {
					if (prob.problem_number !== i+1) {
				 		void store.dispatch('problem_sets/updateSetProblem', { prob, props: { problem_number: i+1 } });
					}
				});
				updateProblemSet();
			}
		};
	}

});
</script>

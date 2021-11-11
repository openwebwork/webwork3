<template>
	<div v-if="problems.length >0" class="scroll" style="height: 700px">
		<draggable
			class="dragArea list-group w-full"
			handle=".move-handle"
			:list="problems"
			@change="reorderProblems"
		>
			<div v-for="(problem,index) in problems" :key="problem.id">
				<problem
					:problemPrefix="`QUESTION_${index + 1}_`"
					class="q-mb-md"
					problemType="set"
					:library_problem="problem"
					:reordering="reordering"
				/>
			</div>
			<!-- <div v-for="(problem) in problems" :key="problem.problem_id"
				style="border: 1px solid black">
				<q-btn size="sm" icon="height" class="move-handle" />
				<div>Problem #: {{ problem.problem_number}}</div>
				<div>Problem ID: {{ problem.problem_id}}</div>
				<div>Reordering: {{ reordering }} </div>
			</div> -->
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
import { LibraryProblem } from '@/store/models/library';
import { ProblemSet } from '@/store/models/problem_sets';
import { sortBy } from 'lodash-es';

export default defineComponent({
	name: 'SetDetailProblems',
	props: {
		set_id: {
			type: String,
			default: '0'
		}
	},
	components: {
		Problem,
		draggable: VueDraggableNext
	},
	setup(props) {
		const store = useStore();
		// copy of the set_id prop and ensure it is a number
		const local_set_id = ref(parseInt(`${props.set_id}`));
		const problems: Ref<Array<LibraryProblem>> = ref([]);
		const problem_set: Ref<ProblemSet> = ref(new ProblemSet());

		// helps handling if the problem is being reordered
		const reordering: Ref<boolean> = ref(false);

		const updateProblemSet = () => {
			problems.value = sortBy(store.state.problem_sets.problems
				.filter(set => set.set_id === local_set_id.value), (prob: LibraryProblem) => prob.problem_number);
			problem_set.value = store.state.problem_sets.problem_sets
				.find(set => set.set_id === local_set_id.value) || new ProblemSet();
		};
		updateProblemSet();

		watch(() => local_set_id, updateProblemSet);

		return {
			problem_set,
			local_set_id,
			problems,
			reordering,
			reorderProblems: () => {
				problems.value.forEach((prob, i) => {
					if (prob.problem_number !== i+1) {
						void store.dispatch('problem_sets/updateSetProblem',
							{ prob, props: { problem_number: i+1 } });
					}
				});
				updateProblemSet();
			}
		};
	}

});
</script>

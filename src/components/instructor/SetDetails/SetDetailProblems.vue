<template>
	<div v-if="problem_set && problem_set.problems.length >0" class="scroll" style="height: 500px">
		<problem
			v-for="(problem,index) in problem_set.problems"
			:sourceFilePath="problem.params.file_path"
			:key="problem.id"
			:problemPrefix="`QUESTION_${index + 1}_`"
			class="q-mb-md"
			problemType="set"
			:library_problem="problem"
			/>
	</div>
	<div class="bg-info" v-else>
		<q-banner dense inline-actions class="text-white bg-info rounded-borders">
		There are no problems associated with this set.  Use the library browser to add problems.
		</q-banner>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import { useStore } from '@/store';
import Problem from '@/components/common/Problem.vue';

export default defineComponent({
	name: 'SetDetailProblems',
	props: {
		set_id: String
	},
	components: {
		Problem
	},
	setup(props) {
		const store = useStore();
		// copy of the set_id prop and ensure it is a number
		const local_set_id = ref(parseInt(`${props.set_id ?? 0}`));
		const problem_set = store.state.problem_sets.problem_sets.find(set => set.set_id === local_set_id.value);
		return {
			problem_set,
			local_set_id
		};
	}

});
</script>

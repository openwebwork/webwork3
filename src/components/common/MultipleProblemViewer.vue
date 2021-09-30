<template>
	<div class="q-ma-md">
		<h3 class="q-my-lg">Multiple Problem Viewer</h3>
		<q-btn type="button" @click="loadProblems" class="q-my-md">Load Problems</q-btn>
		<problem v-for="(problem, index) of problems" :key="problem.file" :sourceFilePath="problem.file"
			:problemPrefix="`QUESTION_${index + 1}_`" class="q-mb-md" />
	</div>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import Problem from './Problem.vue';

export default defineComponent({
	name: 'MultipleProblemViewer',
	components: {
		Problem
	},
	setup() {
		// Test problems:
		const problems = ref<Array<{ file: string }>>([]);

		const loadProblems = () => {
			problems.value.push(
				// Basic problem
				{ file: 'Library/UBC/calculusStewart/divergence6.pg' },
				// Scaffold problem
				{ file: 'Contrib/CUNY/CityTech/CollegeAlgebra_Trig/ParabolaVertices/vertex-CtS-walkthrough.pg' },
				// Geogebra problem
				{ file: 'Contrib/CUNY/CityTech/CollegeAlgebra_Trig/setGeogebra/line-intercepts-blank-canvas.pg' },
				// Problem that contains an image
				{ file: 'Library/Michigan/Chap7Sec5/Q13.pg' },
				// Problem that uses parserWordCompletion so MathQuill is disabled on some of the inputs
				{ file: 'Library/Hope/Multi1/03-05-Basis-subspace/Basis_11_column_space.pg' }
			);
		};

		return { problems, loadProblems };
	}
});
</script>

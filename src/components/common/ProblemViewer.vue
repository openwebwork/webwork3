<template>
	<div class="q-ma-md">
		<h3 class="q-my-lg">Problem Viewer</h3>
		<q-form @submit.prevent="loadProblem">
			<q-input v-model="srcFile" label="Source File" autocomplete />
			<q-btn type="submit" class="q-my-md">Load Problem</q-btn>
		</q-form>
		<problem-vue :problem="problem" />
	</div>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import ProblemVue from './ProblemVue.vue';
import { LibraryProblem } from 'src/common/models/problems';

export default defineComponent({
	name: 'ProblemViewer',
	components: {
		ProblemVue
	},
	setup() {
		const srcFile = ref('');
		const file = ref('');
		const problem = ref<LibraryProblem>(new LibraryProblem());

		// Test problems:
		//   # Basic
		//   Library/UBC/calculusStewart/divergence6.pg
		//   # Scaffold
		//   Contrib/CUNY/CityTech/CollegeAlgebra_Trig/ParabolaVertices/vertex-CtS-walkthrough.pg
		//   # Geogebra
		//   Contrib/CUNY/CityTech/CollegeAlgebra_Trig/setGeogebra/line-intercepts-blank-canvas.pg
		//   # Contains image
		//   Library/Michigan/Chap7Sec5/Q13.pg
		//   # Uses parserWordCompletion so MathQuill is disabled on some of the inputs
		//   Library/Hope/Multi1/03-05-Basis-subspace/Basis_11_column_space.pg

		return {
			srcFile,
			file,
			problem,
			loadProblem: () => {
				problem.value.location_params.set({ file_path: srcFile.value });
			}
		};
	}
});
</script>

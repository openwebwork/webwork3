<template>
	<div class="q-ma-md">
		<h3>Problem Viewer</h3>
		<q-btn @click="loadProblem" class="q-mb-md">Load Problem</q-btn>
		<problem :file="file" />
	</div>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import Problem from './Problem.vue';

export default defineComponent({
	name: 'ProblemViewer',
	components: {
		Problem
	},
	setup(){
		const file = ref('');
		const probs = [
			'Contrib/CUNY/CityTech/CollegeAlgebra_Trig/ParabolaVertices/vertex-CtS-walkthrough.pg',
			'Contrib/CUNY/CityTech/CollegeAlgebra_Trig/setGeogebra/line-intercepts-blank-canvas.pg',
			'Library/UBC/calculusStewart/divergence6.pg'
		];

		return {
			file,
			loadProblem: () => {
				const rand = Math.floor(probs.length*Math.random());
				file.value = probs[rand];
			}
		};
	}
});
</script>

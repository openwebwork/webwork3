<template>
	<div>
		<h3>Problem Viewer</h3>
		<q-btn @click="loadProblem">Load Problem</q-btn>
		<problem :file="file" />
	</div>
</template>

<script lang="ts">
import { defineComponent, Ref, ref } from 'vue';
import Problem from './Problem.vue';

export default defineComponent({
	name: 'ProblemViewer',
	components: {
		Problem
	},
	setup(){
		const file: Ref<string> = ref('');
		const probs = [
			'Library/Hope/Calc1/02-01-Rates-of-change/Thomas12-02-01-03a.pg',
			'Library/UBC/calculusStewart/arcLength5.pg',
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

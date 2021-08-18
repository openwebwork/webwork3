<template>
	<q-card class="q-ma-p-lg">
		<homework-set :set_id="set_id" v-if="set_type==='HW'" />
		<quiz :set_id="set_id" v-else-if="set_type==='QUIZ'" />
	</q-card>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRoute } from 'vue-router';
// import { cloneDeep } from 'lodash-es';

import { useStore } from 'src/store';
import { ProblemSet } from 'src/store/models';
import { newProblemSet } from 'src/store/common';
// import { formatDate } from 'src/common';
import HomeworkSet from './HomeworkSet.vue';
import Quiz from './Quiz.vue';

export default defineComponent({
	name: 'ProblemSetDetails',
	components: {
		HomeworkSet,
		Quiz
	},
	setup() {
		const route = useRoute();
		const store = useStore();
		// const set: Ref<ProblemSet> = ref(newProblemSet());

		// const updateSet = () => {
		// const s = route.params.set_id; // a param is either a string or an array of strings
		// const set_id = Array.isArray(s) ? parseInt(s[0]) : parseInt(s);
		// const _set = store.state.problem_sets.problem_sets
		// .find((_set: ProblemSet) => _set.set_id === set_id);
		// // eslint-disable-next-line @typescript-eslint/no-unsafe-call
		// set.value = (cloneDeep(_set) as ProblemSet) || newProblemSet();
		// };
		// updateSet();

		// watch(() => route.params.set_id, updateSet);

		const parseSetId = () => {
			return Array.isArray(route.params.set_id)
				? parseInt(route.params.set_id[0])
				: parseInt(route.params.set_id);
		};

		return {
			// formatDate,
			// set,

			set_id: computed(() => parseSetId()),
			set_type: computed(() => {
				const _set_id = parseSetId();
				const s = store.state.problem_sets.problem_sets.find((_set: ProblemSet) => _set.set_id == _set_id) ||
					newProblemSet();
				console.log(s);
				return s.set_type;
			})
			// setChanged: (_set: ProblemSet) => {
			// console.log('the set is updated');

			// // handle any errors here.
			// void store.dispatch('problem_sets/updateSet', _set);
			// }
		};
	}
});
</script>

<style type="text/css">
.header {
	font-weight: bold;
	font-size: 120%;
	width: 200px;
}

table#settable {
	margin: 10px;
}
</style>

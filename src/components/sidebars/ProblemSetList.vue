<template>
	<template v-for="set in problem_sets" :key="set.set_id">
		<q-item clickable @click="changeSet(set.set_id)">
			<q-item-section>{{ set.set_name }}</q-item-section>
		</q-item>
	</template>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'ProblemSetList',
	setup() {
		const store = useStore();
		const router = useRouter();

		return {
			problem_sets: computed(() => store.state.problem_sets.problem_sets),
			changeSet: (set_id: number) => {
				void router.push({ name: 'ProblemSetDetails', params: { set_id: set_id } });
			}
		};
	}
});

</script>

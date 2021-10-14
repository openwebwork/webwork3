<template>
	<q-card>
		<q-card-section>
			<div class="text-h6 text-center">Library Options</div>
		</q-card-section>
		<q-card-section>
			<q-select label="target problem set"
				v-model="target_set"
				:options="problem_sets"
				/>
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, computed, ref, watch } from 'vue';
import { useStore } from 'src/store';

interface SelectItem {
	label: string;
	value: number;
}

export default defineComponent({
	name: 'ProblemSetList',
	setup() {
		const store = useStore();
		const target_set: Ref<SelectItem| null> = ref(null);

		watch([target_set], () => {
			void store.dispatch('app_state/setTargetSetID', target_set.value?.value ?? 0);
		});

		return {
			target_set,
			users: computed(() => store.state.users.users),
			problem_sets: computed(() => store.state.problem_sets.problem_sets
				.map(set => ({ label: set.set_name, value: set.set_id })))
		};
	}
});

</script>

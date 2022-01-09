<template>
	<q-page class="q-pa-md">
		<div class="row">
					<q-select
						filled
						style="width: 250px"
						v-model="set_label"
						:options="problem_set_labels"
						label="Select a Problem Set"
					/>
				</div>
		<div class="row">
			<router-view />
		</div>
	</q-page>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'Student',
	setup () {
		const store = useStore();
		const router = useRouter();
		const route = useRoute();
		const set_label = ref<{label: string, value: number } | null>(null);
		if (route.params.set_id) {
			const set_id = Array.isArray(route.params.set_id) ?
				parseInt(route.params.set_id[0]) :
				parseInt(route.params.set_id);
			const set = store.state.problem_sets.merged_user_sets.find(set => set.set_id === set_id);
			if (set) {
				set_label.value = { value: set.set_id ?? 0, label: set.set_name ?? '' };
			}
		}
		watch(() => set_label.value, () => {
			if (set_label.value) {
				void router.push({ name: 'ProblemSets', params: { set_id: set_label.value.value } });
			}
		});

		return {
			set_label,
			problem_set_labels: computed(() => store.state.problem_sets.merged_user_sets.
				map(set => ({ label: set.set_name, value: set.set_id })))
		};
	}
});
</script>

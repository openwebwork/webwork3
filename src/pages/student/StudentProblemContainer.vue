<template>
	<q-page class="q-pa-md">
		<div class="row">
			<div class="col-3">
					<q-select
						filled
						v-model="set_label"
						:options="problem_set_labels"
						label="Select a Problem Set"
					/>
				</div>
				<div class="col-2 q-pa-md" style="font: bold 120%">Problem Number</div>
				<div class="col-7">
					<div class="q-pa-lg flex">
						<q-pagination
							v-model="problem_number"
							:max="num_problems"
							:max-pages="10"
							direction-links
							boundary-links
							icon-first="skip_previous"
							icon-last="skip_next"
							icon-prev="fast_rewind"
							icon-next="fast_forward"
						/>
					</div>
				</div>
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
import { parseNumericRouteParam } from 'src/common';

export default defineComponent({
	name: 'ProblemContainer',
	setup () {
		const store = useStore();
		const router = useRouter();
		const route = useRoute();
		const set_label = ref<{label: string, value: number } | null>(null);
		const problem_number = ref<number>(1);

		const set_id = computed(() => parseNumericRouteParam(route.params.set_id));

		if (route.params.set_id) {
			const set = store.state.problem_sets.merged_user_sets.find(set => set.set_id === set_id.value);
			if (set) {
				set_label.value = { value: set.set_id ?? 0, label: set.set_name ?? '' };
			}
		}

		watch(() => set_label.value, () => {
			void router.push({ name: 'StudentProblemContainer', params: {
				set_id: set_label.value?.value,
				problem_number: 0
			} });
		});

		watch(() => problem_number.value, () => {
			const user_problems = store.state.problem_sets.merged_user_problems.filter(
				prob => prob.set_id === set_id.value);
			void router.push({ name: 'StudentProblem', params: {
				problem_id: user_problems[problem_number.value - 1].problem_id
			} });
		});

		return {
			set_label,
			problem_number,
			num_problems: computed(() => {
				const set_id = set_label.value?.value ?? 0;
				return store.state.problem_sets.merged_user_problems.filter(
					prob => prob.set_id === set_id).length;
			}),
			problem_set_labels: computed(() => store.state.problem_sets.merged_user_sets.
				map(set => ({ label: set.set_name, value: set.set_id })))
		};
	}
});
</script>

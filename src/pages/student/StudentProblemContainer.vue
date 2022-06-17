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

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { parseNumericRouteParam } from 'src/common/views';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';
import { useSessionStore } from 'src/stores/session';

const session_store = useSessionStore();
const problem_sets = useProblemSetStore();
const set_problem_store = useSetProblemStore();
const router = useRouter();
const route = useRoute();
const set_label = ref<{label: string, value: number } | null>(null);
const problem_number = ref<number>(1);

const set_id = computed(() => parseNumericRouteParam(route.params.set_id));

// Load all user problems.  Note: this loads everything.
// Alternatively, maybe only load for a single set and change on set changes.
await set_problem_store.fetchSetProblems(session_store.course.course_id);
await set_problem_store.fetchUserProblemsForUser(session_store.user.user_id);

if (route.params.set_id) {
	const set = problem_sets.user_sets.find(set => set.set_id === set_id.value);
	if (set) {
		set_label.value = { value: set.set_id ?? 0, label: set.set_name ?? '' };
	}
}

// The set changes.
watch(() => set_label.value, () => {
	void router.push({ name: 'StudentProblemContainer', params: {
		set_id: set_label.value?.value,
		problem_number: 0
	} });
});

// The problem changes.
watch(() => problem_number.value, () => {
	const user_problems = set_problem_store.user_problems.filter(
		prob => prob.set_id === set_id.value);
	void router.push({ name: 'StudentProblem', params: {
		problem_id: user_problems[problem_number.value - 1].set_problem_id
	} });
});

const num_problems =  computed(() => {
	const set_id = set_label.value?.value ?? 0;
	return set_problem_store.user_problems.filter(
		prob => prob.set_id === set_id).length;
});

const problem_set_labels = computed(() => problem_sets.user_sets.
	map(set => ({ label: set.set_name, value: set.set_id })));
</script>

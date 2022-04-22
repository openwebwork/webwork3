<template>
	<div>
		<div class="row">
			<div class="col-3">
				<q-select
					:options="problem_sets_info" v-model="selected_set"
					label="Select Problem Set" map-options
				/>
			</div>
			<div class="col-9">
				<q-tabs
					v-if="selected_set"
					v-model="set_details_tab"
					dense
					inline-label
					class="text-teal"
				>
					<q-tab name="details" icon="info" label="Details" />
					<q-tab name="problems" icon="functions" label="Problems" />
					<q-tab name="users" icon="people" label="Users" />
				</q-tabs>
			</div>
		</div>
		<q-tab-panels
			v-if="selected_set"
			v-model="set_details_tab" animated>
			<q-tab-panel name="details">
				<router-view />
			</q-tab-panel>
			<q-tab-panel name="problems">
				<set-detail-problems/>
			</q-tab-panel>
			<q-tab-panel name="users">
				<set-users/>
			</q-tab-panel>
		</q-tab-panels>
	</div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import SetDetailProblems from 'components/instructor/SetDetails/SetDetailProblems.vue';
import SetUsers from 'components/instructor/SetDetails/SetUsers.vue';
import { parseRouteCourseID, parseRouteSetID } from 'src/router/utils';

import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSetProblemStore } from 'src/stores/set_problems';
import { logger } from 'src/boot/logger';

interface SetInfo {
	label: string;
	value: number;
}

const router = useRouter();
const route = useRoute();
const problem_set_store = useProblemSetStore();
const set_problem_store = useSetProblemStore();
const selected_set = ref<SetInfo | null>(null);
const set_details_tab = ref<string>('details');

const set_id = computed(() => parseRouteSetID(route));
const course_id = computed(() => parseRouteCourseID(route));

const loadProblemsAndUserSets = async () => {
	logger.debug('[SetDetailContainer]: loading user sets and set problems.');
	await problem_set_store.fetchUserSets({
		course_id: course_id.value,
		set_id: set_id.value
	});
	await set_problem_store.fetchSetProblems(course_id.value);
};

const problem_sets_info = computed(() => problem_set_store.problem_sets
	.map(set => ({ label: set.set_name, value: set.set_id })));

const updateSet = async () => {
	await loadProblemsAndUserSets();
	const set_info = problem_sets_info.value.find(s => s.value === set_id.value);
	if (set_info) {
		selected_set.value = set_info;
		set_details_tab.value = 'details';
		void router.push({ name: 'ProblemSetDetails', params: { set_id: set_id.value } });
		set_details_tab.value = 'details'; // reset the tabs to the first one.
	};
};

watch(() => set_id.value, updateSet);
watch(() => problem_sets_info.value, updateSet);

// On page load if set_id exists, render the problem set.
if (set_id.value) {
	await updateSet();
}

// If the selected set changes.
watch(() => selected_set.value, () => {
	void router.push({
		name: 'ProblemSetDetails',
		params: { set_id: parseInt(`${selected_set.value?.value ?? 0}`) }
	});
}, { deep: true });
</script>

<style scoped>
#settable {
	width: 100%
}
</style>

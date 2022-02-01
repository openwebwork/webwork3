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

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import SetDetailProblems from 'components/instructor/SetDetails/SetDetailProblems.vue';
import SetUsers from 'components/instructor/SetDetails/SetUsers.vue';
import { parseRouteSetID } from 'src/router/utils';

import { useStore } from 'src/store';

interface SetInfo {
	label: string;
	value: number;
}

export default defineComponent({
	name: 'SetDetailContainer',
	components: {
		SetDetailProblems,
		SetUsers
	},
	setup() {
		const router = useRouter();
		const route = useRoute();
		const store = useStore();
		const selected_set = ref<SetInfo | null>(null);
		const set_details_tab = ref<string>('details');

		const set_id = computed(() => parseRouteSetID(route));

		const problem_sets_info = computed(() => store.state.problem_sets.problem_sets
			.map(set => ({ label: set.set_name, value: set.set_id })));

		// const updateSet = (_set_id: number) => {
		// void router.push({ name: 'ProblemSetDetails', params: { set_id: parseInt(`${_set_id}`) } });
		// set_details_tab.value = 'details'; // reset the tabs to the first one.
		// };

		const updateSet = () => {
			const set_id = parseRouteSetID(route);
			const set_info = problem_sets_info.value.find(s => s.value === set_id);
			if (set_info) {
				selected_set.value = set_info;
				set_details_tab.value = 'details';
			}
		};

		if (set_id.value) {
			updateSet();
		}

		// if (selected_set.value) {
		// updateSet();
		// }

		// updateSet();

		// If there is a link to this page with the set_id parameter, update.
		watch(() => route.params, updateSet);

		// If the selected set changes.
		watch(() => selected_set.value, () => {
			void router.push({
				name: 'ProblemSetDetails',
				params: { set_id: parseInt(`${selected_set.value?.value ?? 0}`) }
			});
		}, { deep: true });

		return {
			selected_set,
			set_details_tab,
			set_id,
			problem_sets_info
		};
	}
});
</script>

<style scoped>
#settable {
	width: 100%
}
</style>

<template>
	<div>
		<div class="row">
			<div class="col-2">
				<div class="q-pl-lg q-pt-sm text-h6"> {{ set_name }} </div>
			</div>
			<div class="col-10">
				<q-tabs
					v-if="selected_set_id"
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
			v-if="selected_set_id"
			v-model="set_details_tab" animated>
			<q-tab-panel name="details">
				<router-view />
			</q-tab-panel>
			<q-tab-panel name="problems">
				<set-detail-problems :set_id="selected_set_id"/>
			</q-tab-panel>
			<q-tab-panel name="users">
				<set-users/>
			</q-tab-panel>
		</q-tab-panels>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import type { Ref } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import SetDetailProblems from '@/components/instructor/SetDetails/SetDetailProblems.vue';
import SetUsers from '@/components/instructor/SetDetails/SetUsers.vue';

import { useStore } from '@/store';

export default defineComponent({
	name: 'SetDetailContainer',
	props: {
		set_id: String
	},
	components: {
		SetDetailProblems,
		SetUsers
	},
	setup() {
		const router = useRouter();
		const route = useRoute();
		const store = useStore();
		const selected_set_id: Ref<number> = ref(0);
		const set_details_tab: Ref<string> = ref('details');

		const updateSet = (_set_id: number) => {
			void router.push({ name: 'ProblemSetDetails', params: { set_id: parseInt(`${_set_id}`) } });
			set_details_tab.value = 'details'; // reset the tabs to the first one.
		};

		const updateSetID = () => {
			const s = route.params.set_id; // a param is either a string or an array of strings
			const set_id = Array.isArray(s) ? parseInt(s[0]) : parseInt(s);
			selected_set_id.value = set_id;
		};

		if(route.params.set_id){
			updateSetID();
		}
		updateSetID();

		watch(() => route.fullPath, updateSetID);

		watch(() => selected_set_id.value, updateSet);

		return {
			set_details_tab,
			selected_set_id,
			set_name: computed(() => {
				const set = store.state.problem_sets.problem_sets.find(_set => _set.set_id === selected_set_id.value);
				return set ? set.set_name : 'Select a set to the right';
			})
		};
	}
});
</script>

<style scoped>
#settable {
	width: 100%
}
</style>

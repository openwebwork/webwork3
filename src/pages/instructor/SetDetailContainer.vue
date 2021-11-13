<template>
	<div v-if="selected_set">
		<q-tabs
			v-model="set_details_tab"
			dense
			inline-label
			class="text-teal"
		>
			<q-tab name="details" icon="info" label="Details" />
			<q-tab name="problems" icon="functions" label="Problems" />
			<q-tab name="users" icon="people" label="Users" />
		</q-tabs>
		<q-tab-panels v-model="set_details_tab" animated>
			<q-tab-panel name="details">
				<router-view />
			</q-tab-panel>
			<q-tab-panel name="problems">
				<set-detail-problems :set_id="set_id"/>
			</q-tab-panel>
			<q-tab-panel name="users">
				<set-users/>
			</q-tab-panel>
		</q-tab-panels>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import SetDetailProblems from '@/components/instructor/SetDetails/SetDetailProblems.vue';
import SetUsers from '@/components/instructor/SetDetails/SetUsers.vue';

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
		const selected_set: Ref<number> = ref(0);
		const set_details_tab: Ref<string> = ref('details');

		const updateSet = (_set_id: number) => {
			void router.push({ name: 'ProblemSetDetails', params: { set_id: _set_id } });
			set_details_tab.value = 'details'; // reset the tabs to the first one.
		};

		const updateSetID = () => {
			const s = route.params.set_id; // a param is either a string or an array of strings
			const set_id = Array.isArray(s) ? parseInt(s[0]) : parseInt(s);
			selected_set.value = set_id;
		};

		if(route.params.set_id){
			updateSetID();
		}

		watch(() => route.fullPath, updateSetID);

		watch(() => selected_set.value, updateSet);

		return {
			set_details_tab,
			selected_set
		};
	}
});
</script>

<style scoped>
#settable {
	width: 100%
}
</style>

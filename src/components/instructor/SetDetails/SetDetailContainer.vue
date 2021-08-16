<template>
	<div class="q-ma-lg">
		<div class="row">
			<div class="col-2 offset-8">
				<q-select v-model="selected_set" :options="problem_set_names"
					emit-value map-options label="Select Set" />
			</div>
		</div>
		<router-view />
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, computed, watch } from 'vue';
import { useStore } from 'src/store';
import { ProblemSet } from 'src/store/models';
import { useRouter, useRoute } from 'vue-router';

export default defineComponent({
	name: 'SetDetailContainer',
	props: {
		set_id: String
	},
	setup() {
		const store = useStore();
		const router = useRouter();
		const route = useRoute();
		const selected_set: Ref<number> = ref(0);

		const updateSet = (_set_id: number) => {
			void router.push({ name: 'ProblemSetDetails', params: { set_id: _set_id } });
		};
		if(route.params.set_id){
			const s = route.params.set_id; // a param is either a string or an array of strings
			const set_id = Array.isArray(s) ? parseInt(s[0]) : parseInt(s);
			selected_set.value = set_id;
			updateSet(set_id);
		}

		watch(() => selected_set.value, updateSet);

		return {
			selected_set,
			problem_set_names: computed(() =>
				store.state.problem_sets.problem_sets
					.map((_set: ProblemSet) => ({ label: _set.set_name, value: _set.set_id }))
			)
		};
	}
});
</script>

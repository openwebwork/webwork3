<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent, ref, Ref, watch } from 'vue';
import { useRouter, useRoute } from 'vue-router';

export default defineComponent({
	name: 'SetDetailContainer',
	props: {
		set_id: String
	},
	setup() {
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

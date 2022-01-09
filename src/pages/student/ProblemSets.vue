<template>
	<h6>Problem Viewer: {{ problem_set.set_name }}</h6>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'src/store';

// import { UserProblem } from 'src/store/models/problems';

export default defineComponent({
	name: 'Problems',
	setup() {
		const route = useRoute();
		const store = useStore();
		const set_id = ref<number | null>(null);

		const updateSetID = () => {
			set_id.value = Array.isArray(route.params.set_id)
				? parseInt(route.params.set_id[0])
				: parseInt(route.params.set_id);
		};

		if (route.params.set_id) updateSetID();
		watch(() => route.params.set_id, updateSetID);

		return {
			set_id,
			problem_set: computed(
				() => store.state.problem_sets.merged_user_sets.find(set => set.set_id === set_id.value)
			),
			user_problems: computed(
				() => []
			)
		};
	}
});
</script>

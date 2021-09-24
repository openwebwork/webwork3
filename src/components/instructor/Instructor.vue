<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	setup(props) {
		const store = useStore();

		if (props.course_id && props.course_name) {
			const course = {
				course_id: props.course_id,
				course_name: props.course_name
			};
			void store.dispatch('session/setCourse', course);
		}
	},
	async created() {
		// fetch most data needed for instrutor views
		const store = useStore();
		const route = useRoute();
		await store.dispatch('users/fetchUsers');
		await store.dispatch('users/fetchCourseUsers', route.params.course_id);
		await store.dispatch('problem_sets/fetchProblemSets', route.params.course_id);
		await store.dispatch('settings/fetchDefaultSettings');
		await store.dispatch('settings/fetchCourseSettings', route.params.course_id);
	}
});
</script>

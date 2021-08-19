<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	setup (props){
		const store = useStore();

		if (props.course_id && props.course_name) {
			const course = {
				course_id: props.course_id,
				course_name: props.course_name
			};
			void store.dispatch('session/setCourse', course);
		}
	},
	async created () {
		// fetch most data needed for instrutor views
		const store = useStore();
		await store.dispatch('users/fetchUsers', store.state.session.course.course_id);
		await store.dispatch('problem_sets/fetchProblemSets', store.state.session.course.course_id);
		await store.dispatch('settings/fetchDefaultSettings');
		await store.dispatch('settings/fetchCourseSettings', store.state.session.course.course_id);
	}
});
</script>

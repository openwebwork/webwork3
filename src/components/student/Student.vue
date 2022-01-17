<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'Student',
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
		return {
			courseName: computed(() => store.state.session.course.course_name)
		};
	},
	async created() {
		const store = useStore();
		await store.dispatch('problem_sets/fetchUserMergedUserSets', store.state.session.user.user_id);
		await store.dispatch('problem_sets/fetchMergedUserProblems', store.state.session.user.user_id);
		await store.dispatch('problem_sets/fetchSetProblems');
	}
});
</script>

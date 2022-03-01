<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useSessionStore } from 'src/stores/session';

export default defineComponent({
	name: 'Student',
	props: {
		course_name: String,
		course_id: String
	},
	setup(props) {
		const session = useSessionStore();

		if (props.course_id && props.course_name) {
			const course = {
				course_id: props.course_id,
				course_name: props.course_name
			};
			void store.dispatch('session/setCourse', course);
		}
		return {
			course_name: computed(() => session.course.course_name)
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

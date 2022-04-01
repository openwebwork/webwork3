<template>
	<h3>Student View for {{ course_name }}</h3>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useSessionStore } from 'src/stores/session';

export default defineComponent({
	name: 'Student',
	setup() {
		const session = useSessionStore();

		return {
			course_name: computed(() => session.course.course_name)
		};
	}
});
</script>

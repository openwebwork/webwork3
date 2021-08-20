<template>
	<h3>Student View for {{ course_name }}</h3>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'Student',
	setup() {
		const store = useStore();

		return {
			course_name: computed(() => store.state.session.course.course_name)
		};
	}
});
</script>

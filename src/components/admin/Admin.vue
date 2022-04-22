<template>
	<router-view />
</template>

<script lang="ts">
import { useCourseStore } from 'src/stores/courses';
import { defineComponent } from 'vue';

export default defineComponent({
	name: 'Admin',
	created() {
		const courses = useCourseStore();
		void courses.fetchCourses();
	}
});
</script>

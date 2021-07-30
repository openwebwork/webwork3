<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
// import { useStore } from 'vuex';
export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String
	}
});
</script>
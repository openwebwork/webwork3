<template>
	<h3>Instructor View</h3>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
// import { useStore } from 'vuex';
export default defineComponent({
	name: 'Instructor',
	props: ['course_name'],
	setup(props) {

		console.log(props);
	}
});
</script>
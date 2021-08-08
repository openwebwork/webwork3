<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent} from 'vue';
import { useStore } from '../../store';

export default defineComponent({
	name: 'Admin',
	// setup() {
	// 	console.log('in admin');
	// },
	async created () {
		// fetch most data needed for instrutor views
		const store = useStore();
		await store.dispatch('courses/fetchCourses');
	},

})

</script>
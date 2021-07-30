<template>
	<h3>Settings</h3>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useStore } from '../../store';
export default defineComponent({
	name: 'Settings',
	setup() {
		console.log('in setup()');
	},
	async created () {
		// fetch the data when the view is created and the data is
		// already being observed
		const store = useStore();
		console.log(store);
		await store.dispatch('settings/fetchDefaultSettings');
		await store.dispatch('settings/fetchCourseSettings');
  },

});
</script>
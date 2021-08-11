<template>
	<q-layout view="hHh Lpr lFf">
		<menu-bar  @toggle="toggleSidebar"/>

		<q-drawer
			v-model="sidebar_open"
			bordered
			class="bg-grey-1"
		>

		<menu-sidebar />
		</q-drawer>

		<q-page-container>
			<router-view />
		</q-page-container>
	</q-layout>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import MenuSidebar from './MenuSidebar.vue';
import MenuBar from './MenuBar.vue';

export default defineComponent({
	components: {
		MenuSidebar,
		MenuBar
	},
	emits: ['toggleMenuSidebar'],
	setup() {
		const sidebar_open = ref(true);
		return {
			sidebar_open,
			toggleSidebar: () => sidebar_open.value = !sidebar_open.value
		};
	}
});
</script>

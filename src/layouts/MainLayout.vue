<template>
	<q-layout view="lHh Lpr lFf">
		<menu-bar />

		<q-drawer
			v-model="sidebar_open"
			bordered
			class="bg-grey-1"
		>
			<q-list>
				<q-item-label
					header
					class="text-grey-8"
				>
					Essential Links
				</q-item-label>
			</q-list>
		</q-drawer>

		<q-page-container>
			<router-view />
		</q-page-container>
	</q-layout>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import MenuBar from 'components/common/MenuBar.vue';

export default defineComponent({
	components: {
		MenuBar
	},
	setup() {
		const sidebar_open = ref(false);
		return {
			sidebar_open
		};
	}
});
</script>

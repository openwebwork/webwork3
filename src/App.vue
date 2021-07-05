<template>
<q-layout view="hHh lpR fFf">
		<menu-bar />
		<q-footer>
			<q-toolbar class="bg-dark" >
				<q-toolbar-title style="font: bold; font-size: 75%">&copy; 2000-2021, <a href="https://openwebwork.org">openwebwork.org</a></q-toolbar-title>
			</q-toolbar>
		</q-footer>
		<q-drawer show-if-above v-model="leftDrawerOpen" side="right" bordered>
			<q-card>
				<q-card-section>
					<h2>Hi</h2>
				</q-card-section>
			</q-card>
		</q-drawer>

		<q-page-container id="main">
			<router-view />
		</q-page-container>
	</q-layout>
</template>

<script lang="ts">
import MenuBar from "@/components/common/MenuBar.vue";
import { ref, Ref, defineComponent } from 'vue';
export default defineComponent({
	components: {
		MenuBar
	},
	setup() {
		const leftDrawerOpen: Ref<boolean> = ref(false);
		return { leftDrawerOpen };
	}
});
</script>

<style lang="scss">
#app {
	font-family: Avenir, Helvetica, Arial, sans-serif;
	-webkit-font-smoothing: antialiased;
	-moz-osx-font-smoothing: grayscale;
	color: #2c3e50;
}

#main {
	margin-top: 20px;
}
</style>

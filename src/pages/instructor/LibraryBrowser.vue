<template>
	<q-page>
		<q-tab-panels v-model="tab" style="padding-top:40px">
			<q-tab-panel name="OPL">
				<lib-panel-opl />
			</q-tab-panel>
			<q-tab-panel name="dir">
				<lib-panel-dir />
			</q-tab-panel>

			<q-tab-panel name="local">
				<lib-panel-local />
			</q-tab-panel>
			<q-tab-panel name="search">
				<lib-panel-search />
			</q-tab-panel>
		</q-tab-panels>

		<q-page-sticky position="top" expand class="bg-indigo-7 text-white shadow-2">
			<q-tabs
				v-model="tab"
				dense
				align="justify"
			>
				<q-tab name="OPL" label="Open Problem Library" />
				<q-tab name="dir" label="Directory" />
				<q-tab name="local" label="Local Problems" />
				<q-tab name="search" label="Search" />
			</q-tabs>
		</q-page-sticky>
	</q-page>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import LibPanelOpl from 'src/components/instructor/LibraryComponents/LibPanelOPL.vue';
import LibPanelDir from 'src/components/instructor/LibraryComponents/LibPanelDir.vue';
import LibPanelLocal from 'src/components/instructor/LibraryComponents/LibPanelLocal.vue';
import LibPanelSearch from 'src/components/instructor/LibraryComponents/LibPanelSearch.vue';

export default defineComponent({
	name: 'LibraryBrowser',
	components: {
		LibPanelOpl,
		LibPanelDir,
		LibPanelLocal,
		LibPanelSearch
	},
	setup () {
		return {
			tab: ref('')
		};
	}
});
</script>

<template>
	<q-card>
		<q-tabs
			v-model="tab"
			dense
			align="justify"
			class="bg-indigo-7 text-white shadow-2"
			:breakpoint="0"
		>
			<q-tab name="OPL" label="Open Problem Library" />
			<q-tab name="dir" label="Directory" />
			<q-tab name="local" label="Local Problems" />
			<q-tab name="search" label="Search" />
		</q-tabs>
		<q-separator />

		<q-tab-panels v-model="tab">
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
	</q-card>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import LibPanelOpl from './LibraryComponents/LibPanelOPL.vue';
import LibPanelDir from './LibraryComponents/LibPanelDir.vue';
import LibPanelLocal from './LibraryComponents/LibPanelLocal.vue';
import LibPanelSearch from './LibraryComponents/LibPanelSearch.vue';
// import { useStore } from 'vuex';

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

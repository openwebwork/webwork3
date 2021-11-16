<template>
	<q-layout view="hHh Lpr lFf">
		<menu-bar
			@toggle-menu="left_sidebar_open = !left_sidebar_open"
			@toggle-sidebar="right_sidebar_open = !right_sidebar_open"
			/>

		<q-drawer :width="250" show-if-above v-model="left_sidebar_open" bordered class="bg-grey-1" >
			<menu-sidebar />
		</q-drawer>

		<q-page-container>
			<router-view />
		</q-page-container>

<!-- this only opens the first sidebar in the list
	TODO: if the sidebars array has length >0, need to be able to select
	the sidebar -->
		<q-drawer :width="250" show-if-above v-if="right_sidebar_open" side="right" bordered class="bg-grey-1" >
			<problem-set-list v-if="sidebars[0] === 'problem_sets'"/>
			<user-list v-else-if="sidebars[0] === 'users'" />
			<library-sidebar v-else-if="sidebars[0] === 'library'"/>
		</q-drawer>

	</q-layout>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, watch } from 'vue';
import { isUndefined } from 'lodash-es';

import MenuSidebar from './MenuSidebar.vue';
import MenuBar from './MenuBar.vue';

import { instructor_views, admin_views, ViewInfo } from 'src/common';
import { useRoute } from 'vue-router';
import ProblemSetList from 'components/sidebars/ProblemSetList.vue';
import UserList from 'components/sidebars/UserList.vue';
import LibrarySidebar from 'components/sidebars/LibrarySidebar.vue';
import { logger } from 'boot/logger';

export default defineComponent({
	components: {
		MenuSidebar,
		ProblemSetList,
		UserList,
		LibrarySidebar,
		MenuBar
	},
	setup() {
		const route = useRoute();
		const left_sidebar_open: Ref<boolean> = ref(true);
		const right_sidebar_open: Ref<boolean> = ref(false);
		const sidebars: Ref<Array<string>> = ref([]);
		// const show_problem_sets: Ref<boolean> = ref(false);
		// const show_users: Ref<boolean> = ref(false);

		// is there any state/scope issue with route?
		// should route: RouteLocationNormalizedLoaded be an argument?
		const updateViews = () => {
			const views = /^\/admin/.exec(route.path)
				? admin_views
				: /^\/courses\/\d+\/instructor/.exec(route.path)
					? instructor_views
					: [];
			let current_view = views.find((view: ViewInfo) => view.component_name === route.name);

			if (! current_view) { // it may be a child component
				current_view = views.find((view: ViewInfo) =>
				 isUndefined(view.children) ? false : view.children?.indexOf(route.name as string)> -1);
			}

			logger.debug(`[MainLayout/updateViews] name: ${current_view?.name || 'no name!'}`);
			if (current_view) {
				sidebars.value = current_view.sidebars;
				if (current_view.sidebars.length>0) {
					logger.debug(`[MainLayout/updateViews] sidebar: ${current_view.sidebars.join(', ')}`);
					right_sidebar_open.value = true;
				} else {
					logger.debug('[MainLayout/updateViews] empty sidebar -- hiding right sidebar!');
					right_sidebar_open.value = false;
				}
			}
		};

		updateViews(); // set views on initial page load
		watch(() => route.name, () => updateViews());

		return {
			left_sidebar_open,
			right_sidebar_open,
			sidebars
		};
	},
});
</script>

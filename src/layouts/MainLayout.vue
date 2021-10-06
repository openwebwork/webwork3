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

		<q-drawer :width="250" show-if-above v-if="right_sidebar_open" side="right" bordered class="bg-grey-1" >
			<problem-set-list v-if="show_problem_sets"/>
			<user-list v-if="show_users" />
			<library-sidebar />
		</q-drawer>

	</q-layout>
</template>

<script lang="ts">
import { defineComponent, ref, watch, Ref } from 'vue';
import MenuSidebar from './MenuSidebar.vue';
import MenuBar from './MenuBar.vue';

import { instructor_views, admin_views, ViewInfo } from 'src/common';
import { useRoute } from 'vue-router';
import ProblemSetList from 'src/components/sidebars/ProblemSetList.vue';
import UserList from 'src/components/sidebars/UserList.vue';
import LibrarySidebar from 'src/components/sidebars/LibrarySidebar.vue';

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
		const show_problem_sets: Ref<boolean> = ref(false);
		const show_users: Ref<boolean> = ref(false);

		watch(() => route.name,
			() => {
				const views = /^\/admin/.exec(route.path)
					? admin_views
					: /^\/courses\/\d+\/instructor/.exec(route.path)
						? instructor_views
						: [];
				const current_view = views.find((view: ViewInfo) => view.component_name === route.name);
				if (current_view) {
					if (current_view.sidebars.length>0) {
						right_sidebar_open.value = true;
					}
				}
			});

		return {
			left_sidebar_open,
			right_sidebar_open,
			show_problem_sets,
			show_users
		};
	}
});
</script>

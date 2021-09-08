<template>
	<q-layout view="hHh Lpr lFf">
		<menu-bar  @toggle="toggleMenuSidebar"/>

		<q-drawer :width="250" show-if-above v-model="left_sidebar_open" bordered class="bg-grey-1" >
			<menu-sidebar />
		</q-drawer>

		<q-page-container>
			<router-view />
		</q-page-container>

		<q-drawer :width="250" show-if-above v-model="right_sidebar_open" side="right" bordered class="bg-grey-1" >
			<problem-set-list v-if="show_problem_sets"/>
			<user-list v-if="show_users" />
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

export default defineComponent({
	components: {
		MenuSidebar,
		ProblemSetList,
		UserList,
		MenuBar
	},
	emits: ['toggleMenuSidebar'],
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
				if(current_view) {
					right_sidebar_open.value = current_view.show_set || current_view?.show_user;
					show_problem_sets.value = current_view.show_set;
					show_users.value = current_view.show_user;
				}
			});

		return {
			left_sidebar_open,
			right_sidebar_open,
			toggleMenuSidebar: () => left_sidebar_open.value = !left_sidebar_open.value,
			show_problem_sets,
			show_users
		};
	}
});
</script>

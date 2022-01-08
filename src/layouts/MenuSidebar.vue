<template>
	<template v-for="view in views" :key="view">
		<q-item clickable v-close-popup @click="changeView(view)" :icon="view.icon">
			<q-item-section avatar>
				<q-icon :name="view.icon" />
			</q-item-section>
			<q-item-section>{{ view.name }}</q-item-section>
		</q-item>
	</template>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { instructor_views, admin_views, student_views, ViewInfo } from 'src/common';
import { useRouter, useRoute } from 'vue-router';

export default defineComponent({
	name: 'MenuSidebar',
	setup() {
		const route = useRoute();
		const router = useRouter();
		const sidebar_open = ref<boolean>(false);
		return {
			sidebar_open,
			views: computed(() =>
				/^\/admin/.exec(route.path)
					? admin_views
					: /^\/courses\/\d+\/instructor/.exec(route.path)
						? instructor_views
						: student_views
			),
			changeView: (view: ViewInfo) => {
				void router.push({ name: view.component_name, params: route.params });
			}
		};
	}
});
</script>

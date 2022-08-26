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
import { instructor_views, admin_views, student_views, ViewInfo } from 'src/common/views';
import { useRouter, useRoute } from 'vue-router';
import { useSessionStore } from 'src/stores/session';

export default defineComponent({
	name: 'MenuSidebar',
	setup() {
		const route = useRoute();
		const router = useRouter();
		const session = useSessionStore();
		const sidebar_open = ref<boolean>(false);
		return {
			sidebar_open,
			views: computed(() =>
				/^\/admin/.exec(route.path)
					? admin_views
					: session.course.role === 'instructor'
						? instructor_views
						: session.course.role === 'student'
							? student_views
							: []
			),
			changeView: (view: ViewInfo) => {
				void router.push({ name: view.component_name, params: route.params });
			}
		};
	}
});
</script>

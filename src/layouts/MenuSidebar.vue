<template>
	<template v-for="view in views" :key="view">
		<q-item clickable v-close-popup @click="changeView(view)" :icon="view.icon">
			<q-item-section avatar>
				<q-icon :name="view.icon" />
			</q-item-section>
			<q-item-section>{{view.name}}</q-item-section>
		</q-item>
	</template>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, computed } from 'vue';
import { instructor_views, admin_views, MenuBarView } from 'src/common';
import { useRouter, useRoute } from 'vue-router';

export default defineComponent({
	setup() {
		const route = useRoute();
		const router = useRouter();
		const sidebar_open: Ref<boolean> = ref(false);
		return {
			sidebar_open,
			views: computed(() => (/^\/admin/.exec(route.path)) ?
				admin_views :
				(/^\/courses\/\d+\/instructor/.exec(route.path)) ?
					instructor_views :
					[]),
			changeView: (view: MenuBarView) => {
				// current_view.value = view.name;
				void router.push({ name: view.component_name, params: route.params });
			}
		};
	}
});
</script>

<template>
	<q-page class="q-pa-md">
		<div class="row">
			<div class="col-4">
				<q-card>
					<q-card-section>
						<div class="text-h6">Open Sets</div>
					</q-card-section>
					<q-list>
						<q-item
							clickable
							v-for="set in open_sets"
							:key="set.set_id"
							:to="{name: 'ProblemSets', params: { set_id: set.set_id }}"
						>
						{{ set.set_name }}
						</q-item>
					</q-list>
				</q-card>
			</div>
			<div class="col-4">
				<q-card>
					<q-card-section>
						<div class="text-h6">Closed Sets</div>
					</q-card-section>
				</q-card></div>
		</div>
	</q-page>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'StudentDashboard',
	setup() {
		const store = useStore();
		return {
			open_sets: computed(() => store.state.problem_sets.merged_user_sets)
		};
	}
});
</script>

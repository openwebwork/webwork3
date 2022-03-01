<template>
	<q-card>
		<q-card-section>
			<div class="text-h6 text-center">Library Options</div>
		</q-card-section>
		<q-card-section>
			<q-select label="target problem set"
				v-model="target_set"
				:options="problem_sets"
				/>
			<q-btn push label="View Target Set" @click="viewTargetSet" />
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';
import { useAppStateStore } from 'src/stores/app_state';
import { useUserStore } from 'src/stores/users';
import { useRouter } from 'vue-router';
import { useProblemSetStore } from 'src/stores/problem_sets';

interface SelectItem {
	label: string;
	value: number;
}

export default defineComponent({
	name: 'ProblemSetList',
	setup() {
		const app_state = useAppStateStore();
		const users = useUserStore();
		const problem_sets = useProblemSetStore();
		const router = useRouter();
		const target_set = ref<SelectItem | null>(null);

		watch([target_set], () => {
			void app_state.setTargetSetID(target_set.value?.value ?? 0);
		});

		return {
			target_set,
			users: computed(() => users.users),
			problem_sets: computed(() => problem_sets.problem_sets
				.map(set => ({ label: set.set_name, value: set.set_id }))),
			viewTargetSet: () => {
				if (target_set.value) {
					void router.push({ name: 'ProblemSetDetails', params: { set_id: target_set.value.value } });
				}
			}
		};
	}
});

</script>

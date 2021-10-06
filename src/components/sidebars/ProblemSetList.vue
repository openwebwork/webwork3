<template>
	<q-card>
		<q-card-section>
			<div class="text-h6 text-center">Problem Sets</div>
		</q-card-section>
		<q-card-section>

			<q-list dense>
				<q-item clickable
					v-for="set in problem_sets"
					:key="set.set_id"
					@click="changeSet(set.set_id)"
					>
					<span>
						<q-badge color="green" v-if="set.set_type === 'HW'">H</q-badge>
						<q-badge color="purple" v-if="set.set_type === 'QUIZ'">Q</q-badge>
						<q-badge color="orange" v-if="set.set_type === 'REVIEW'">R</q-badge>
							{{ set.set_name }}
					</span>
				</q-item>
			</q-list>
		</q-card-section>
	</q-card>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'ProblemSetList',
	setup() {
		const store = useStore();
		const router = useRouter();

		return {
			problem_sets: computed(() => store.state.problem_sets.problem_sets),
			changeSet: (set_id: number) => {
				void router.push({ name: 'ProblemSetDetails', params: { set_id: set_id } });
			}
		};
	}
});

</script>

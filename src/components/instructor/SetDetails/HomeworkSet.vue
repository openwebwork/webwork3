<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><q-input v-model="set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="set.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="set.set_visible" /></td>
		</tr>
		<tr>
			<td class="header">Enable Reduced Scoring</td>
			<td><q-toggle v-model="set.set_params.enable_reduced_scoring" /></td>
		</tr>
		<homework-dates v-if="set"
			:dates="set.set_dates"
			:reduced_scoring="set.set_params.enable_reduced_scoring"
		/>
	</table>
</template>

<script lang="ts">
import { defineComponent, ref, watch, computed } from 'vue';
import { useQuasar } from 'quasar';
import { useRoute } from 'vue-router';
import { parseRouteSetID } from 'src/router/utils';

import HomeworkDates from './HomeworkDates.vue';
import { HomeworkSet } from 'src/common/models/problem_sets';
import { useStore } from 'src/store';
import { cloneDeep } from 'lodash';
import { pick } from 'src/common/utils';
import { Dictionary, generic } from 'src/common/models';

export default defineComponent({
	components: {
		HomeworkDates
	},
	name: 'HomeworkSet',
	setup() {
		const store = useStore();
		const route = useRoute();
		const $q = useQuasar();

		const set = ref<HomeworkSet>(new HomeworkSet());

		const set_id = computed(() => parseRouteSetID(route));

		const updateSet = () => {
			const s = store.state.problem_sets.problem_sets.find((_set) => _set.set_id === set_id.value) ??
				new HomeworkSet();
			// Why isn't clone() always available?  Sometimes when the page is refreshed.
			// This may be a bug of vuex-persistance.
			if (s.clone) {
				set.value = s.clone() as unknown as HomeworkSet;
			} else {
				set.value = new HomeworkSet(pick(s as unknown as Dictionary<generic>, HomeworkSet.ALL_FIELDS));
			}
		};

		watch(() => set_id.value, updateSet);
		updateSet();

		// see the docs at https://v3.vuejs.org/guide/reactivity-computed-watchers.html#watching-reactive-objects
		// for why we need to do a cloneDeep here
		watch(() => cloneDeep(set.value), (new_set, old_set) => {
			// don't update if the homework set changes.
			if (new_set['set_id'] == old_set['set_id']) {
				void store.dispatch('problem_sets/updateSet', set.value);
				$q.notify({
					message: `The problem set '${new_set.set_name}' was successfully updated.`,
					color: 'green'
				});

			}
		}, { deep: true });

		return {
			set,
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
			set_id
		};
	}
});
</script>

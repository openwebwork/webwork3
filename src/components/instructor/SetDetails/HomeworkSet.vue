<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><input-with-blur v-model="homework_set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="homework_set.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="homework_set.set_visible" /></td>
		</tr>
		<tr>
			<td class="header">Enable Reduced Scoring</td>
			<td><q-toggle v-model="homework_set.set_params.enable_reduced_scoring" /></td>
		</tr>
		<homework-dates v-if="homework_set"
			:dates="homework_set.set_dates"
			:reduced_scoring="homework_set.set_params.enable_reduced_scoring"
		/>
	</table>
</template>

<script lang="ts">
import { defineComponent, computed, watch, ref } from 'vue';
import { useRoute } from 'vue-router';
import { parseRouteSetID } from 'src/router/utils';

import HomeworkDates from './HomeworkDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { HomeworkSet } from 'src/common/models/problem_sets';

export default defineComponent({
	components: {
		HomeworkDates,
		InputWithBlur
	},
	props: {
		set: {
			type: HomeworkSet,
			required: true
		}
	},
	name: 'HomeworkSet',
	emits: ['updateSet'],
	setup(props, { emit }) {
		const route = useRoute();

		const set_id = computed(() => parseRouteSetID(route));
		const homework_set = ref<HomeworkSet>(props.set.clone());

		watch(() => homework_set.value.clone(), () => {
			emit('updateSet', homework_set.value);
		},
		{ deep: true });

		return {
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
			set_id,
			homework_set
		};
	}
});
</script>

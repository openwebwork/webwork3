<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><input-with-blur v-model="review_set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td><q-select :options="set_options" v-model="review_set.set_type"
				emit-value map-options/></td>
		</tr>
		<tr>
			<td class="header">Visible</td>
			<td><q-toggle v-model="review_set.set_visible" /></td>
		</tr>
		<review-set-dates v-if="set"
			:dates="review_set.set_dates"
			/>
	</table>
</template>

<script lang="ts">
import { defineComponent, ref, watch, computed } from 'vue';

import ReviewSetDates from './ReviewSetDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { ReviewSet } from 'src/common/models/problem_sets';
import { useRoute } from 'vue-router';
import { parseRouteSetID } from 'src/router/utils';

export default defineComponent({
	components: {
		ReviewSetDates,
		InputWithBlur
	},
	props: {
		set: {
			type: ReviewSet,
			required: true
		}
	},
	name: 'ReviewSet',
	setup(props, { emit }) {
		const route = useRoute();

		const set_id = computed(() => parseRouteSetID(route));
		const review_set = ref<ReviewSet>(props.set.clone());

		watch(() => review_set.value.clone(), () => {
			emit('updateSet', review_set.value);
		},
		{ deep: true });

		return {
			set_options: [ // probably should be a course_setting or in common.ts
				{ value: 'REVIEW', label: 'Review set' },
				{ value: 'QUIZ', label: 'Quiz' },
				{ value: 'HW', label: 'Homework set' }
			],
			set_id,
			review_set
		};
	}
});
</script>

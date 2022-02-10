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
		<review-set-dates-input v-if="set"
			:dates="review_set.set_dates"
			@update-dates="updateDates"
			/>
	</table>
</template>

<script lang="ts">
import { defineComponent, ref, watch } from 'vue';

import ReviewSetDatesInput from './ReviewSetDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { ReviewSet, ReviewSetDates } from 'src/common/models/problem_sets';
import { problem_set_type_options } from 'src/common/views';

export default defineComponent({
	components: {
		ReviewSetDatesInput,
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
		const review_set = ref<ReviewSet>(props.set.clone());

		watch(() => props.set, () => {
			review_set.value = props.set.clone();
		}, { deep: true });

		watch(() => review_set.value.clone(), (new_set, old_set) => {
			if (JSON.stringify(new_set) !== JSON.stringify(old_set)) {
				emit('updateSet', review_set.value);
			}
		},
		{ deep: true });

		return {
			set_options: problem_set_type_options,
			review_set,
			updateDates: (dates: ReviewSetDates) => {
				review_set.value.set_dates.set(dates.toObject());
			},
		};
	}
});
</script>

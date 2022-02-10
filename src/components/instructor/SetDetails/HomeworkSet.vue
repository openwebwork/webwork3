<template>
	<table id="settable">
		<tr>
			<td class="header">Set Name</td>
			<td><input-with-blur v-model="homework_set.set_name" /></td>
		</tr>
		<tr>
			<td class="header">Set Type</td>
			<td>
				<q-select
					map-options
					:options="set_options"
					v-model="set_type"
					@update:model-value="$emit('changeSetType', set_type)"
				/>
			</td>
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
			@update-dates="updateDates"
			:reduced_scoring="homework_set.set_params.enable_reduced_scoring"
		/>
	</table>

</template>

<script lang="ts">
import { defineComponent, watch, ref } from 'vue';

import HomeworkDates from './HomeworkDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { HomeworkSet, HomeworkSetDates } from 'src/common/models/problem_sets';
import { problem_set_type_options } from 'src/common/views';

export default defineComponent({
	components: {
		HomeworkDates,
		InputWithBlur
	},
	props: {
		set: {
			type: HomeworkSet,
			required: true
		},
		reset_set_type: {
			type: String,
			required: false
		}
	},
	name: 'HomeworkSet',
	emits: ['updateSet', 'changeSetType'],
	setup(props, { emit }) {
		const homework_set = ref<HomeworkSet>(props.set.clone());
		const set_type = ref<string | undefined>(props.set.set_type);

		// If a set type changed is cancelled this resets to the original.
		watch(() => props.reset_set_type, () => {
			set_type.value = props.reset_set_type;
		});

		watch(() => props.set, () => {
			homework_set.value = props.set.clone();
		}, { deep: true });

		watch(() => homework_set.value.clone(), (new_set, old_set) => {
			if (JSON.stringify(new_set) !== JSON.stringify(old_set)) {
				emit('updateSet', homework_set.value);
			}
		},
		{ deep: true });

		return {
			set_type,
			set_options: problem_set_type_options,
			homework_set,
			updateDates: (dates: HomeworkSetDates) => {
				homework_set.value.set_dates.set(dates.toObject());
			}
		};
	}
});
</script>

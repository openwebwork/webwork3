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
			:dates="(homework_set.set_dates as HomeworkSetDates)"
			@update-dates="updateDates"
			:reduced_scoring="homework_set.set_params.enable_reduced_scoring"
		/>
	</table>

</template>

<script setup lang="ts">
import { watch, ref, defineProps, defineEmits } from 'vue';

import HomeworkDates from './HomeworkDates.vue';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { HomeworkSet, HomeworkSetDates } from 'src/common/models/problem_sets';
import { problem_set_type_options } from 'src/common/views';
import { logger } from 'src/boot/logger';

const props = defineProps({
	set: {
		type: HomeworkSet,
		required: true
	},
	reset_set_type: {
		type: String,
		required: false
	}
});

interface HWDates {
	open: number;
	reduced_scoring: number;
	due: number;
	answer: number;
}

const emit = defineEmits(['updateSet', 'changeSetType']);

const homework_set = ref<HomeworkSet>(props.set.clone());
const set_type = ref<string | undefined>(props.set.set_type);
const set_options = problem_set_type_options;
const hw_dates = ref<HWDates>(homework_set.value.set_dates.toObject() as unknown as HWDates);

// If a set type changed is cancelled this resets to the original.
watch(() => props.reset_set_type, () => {
	set_type.value = props.reset_set_type;
});

watch(() => props.set, (new_set, old_set) => {
	logger.debug(`[HomeworkSet] parent changed homework set from: ${old_set.set_name} to ${new_set.set_name}`);
	homework_set.value = props.set.clone();
	hw_dates.value = homework_set.value.set_dates.toObject() as unknown as HWDates;
});

watch(() => homework_set.value, () => {
	logger.debug('[HomeworkSet] detected mutation in homework_set...');
	emit('updateSet', homework_set.value);
},
{ deep: true });

const updateDates = (dates: HomeworkSetDates) => {
	logger.debug('[HomeworkSet/updateDates] setting dates on homework_set.');
	homework_set.value.set_dates.set(dates.toObject());
};
</script>

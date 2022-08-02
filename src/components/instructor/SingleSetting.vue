<template>
	<tr>
		<td width="60%">{{ setting.description }}
			<q-icon v-if="setting.doc" name="help" class="q-ml-md">
				<q-tooltip class="text-body2">
					{{ setting.doc }}
				</q-tooltip>
			</q-icon>
		</td>
		<td width="40%">
			<input-with-blur
				outlined dense
				v-if="setting?.type === 'text' || setting?.type === 'timezone'"
				v-model="course_setting.value"
			/>
			<q-select v-if="setting.type === 'list'" v-model="option" :options="options" />
			<input-with-blur
				v-if="setting.type === 'time_duration'"
				v-model="course_setting.value"
				:rules="[checkTimeDuration]"
			/>
			<q-toggle v-if="setting.type === 'boolean'" v-model="course_setting.value" />
			<q-input v-if="setting.type === 'integer'" v-model="course_setting.value" :rules="[checkInt]" />
		</td>
	</tr>
</template>

<script setup lang="ts">
import { defineProps, ref, watch } from 'vue';
import { useQuasar } from 'quasar';
import { CourseSetting, OptionType } from 'src/common/models/settings';

import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { logger } from 'src/boot/logger';

import { useSettingsStore } from 'src/stores/settings';
import { isTimeDuration } from 'src/common/models/parsers';

const props = defineProps<{
	setting: CourseSetting
}>();

const $q = useQuasar();
const settings = useSettingsStore();

const course_setting = ref(props.setting.clone());

const option = ref<OptionType>({ value: '', label: '' });
const options = ref<Array<OptionType>>([]);

const checkInt = (val: string) => Number.isInteger(val) ? true : 'This must be an integer.';
const checkTimeDuration = (val: string) => isTimeDuration(val) ? true : 'This must be a time duration.';

if (course_setting.value.options) {
	options.value = course_setting.value.options.map((opt: string | OptionType) =>
		typeof opt === 'string' ? { label: opt, value: opt } : opt
	);
	const v = options.value.find((opt: OptionType) => opt.value === course_setting.value.value);
	option.value = v || { value: '', label: '' };
}

watch(() => course_setting.value.value, async () => {
	try {
		await settings.updateCourseSetting(course_setting.value as CourseSetting);
		const msg = `The setting '${course_setting.value.setting_name}' was updated successfully`;
		$q.notify({
			message: msg,
			color: 'green'
		});
		logger.debug(`[CourseSettings/updateCourseSetting]: ${msg}`);
	} catch (err) {
		$q.notify({ message: err as string, color: 'red' });
		logger.error(`[CourseSettings/updateCourseSetting]: ${err as string}`);
	}
});
</script>

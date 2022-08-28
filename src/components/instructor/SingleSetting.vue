<template>
	<tr>
		<td width="60%">{{ setting.description }}
			<q-icon v-if="setting.doc" name="help" size="sm" color="primary"
				class="q-ml-md" @click="show_help = !show_help"
			/>
		</td>
		<td width="40%">
			<input-with-blur
				outlined dense
				v-if="setting?.type === 'text'"
				v-model="setting_value"
			/>
			<input-with-blur
				outlined dense
				v-if="setting?.type === 'decimal'"
				v-model.number="setting_value"
				type="number"
			/>
			<input-with-blur
				outlined dense
				v-if="setting?.type === 'timezone'"
				v-model="setting_value"
				:error="!valid_timezone"
				error-message="This is not a valid timezone"
			/>
			<q-select v-if="setting.type === 'list'" v-model="option_value" :options="options" />
			<q-select v-if="setting.type === 'multilist'" multiple v-model="multilist_value" :options="options" />
			<input-with-blur
				v-if="setting.type === 'time_duration'"
				v-model="time_duration_value"
				lazy-rules
				:rules="[checkTimeDuration]"
			/>
			<q-toggle v-if="setting.type === 'boolean'" v-model="setting_value" />
			<q-input v-if="setting.type === 'int'" v-model.number="setting_value" type="number" :rules="[checkInt]" />
		</td>
	</tr>
	<tr v-if="setting.doc && show_help"><td class="helptext" colspan="2"><div v-html="setting.doc" /></td></tr>
</template>

<script setup lang="ts">
import { defineProps, ref, watch } from 'vue';
import { useQuasar } from 'quasar';

import { logger } from 'src/boot/logger';
import { api } from 'src/boot/axios';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { useSettingsStore } from 'src/stores/settings';

import { convertTimeDuration, humanReadableTimeDuration, isTimeDuration } from 'src/common/models/parsers';
import { CourseSetting, OptionType, SettingValueType } from 'src/common/models/settings';

const props = defineProps<{
	setting: CourseSetting
}>();

const $q = useQuasar();
const settings = useSettingsStore();

const course_setting = ref(props.setting.clone());
// used for text input/toggles
const setting_value = ref<SettingValueType>();
if (['int', 'decimal', 'text', 'boolean', 'time_duration', 'timezone'].includes(course_setting.value.type)) {
	setting_value.value = course_setting.value.value;
}
// Used for type list and multilist
const option_value = ref<OptionType>({ value: '', label: '' });
const multilist_value = ref<OptionType[]>([]);
const options = ref<OptionType[]>([]);

// Needed for time_duration
const time_duration_value = ref('');

// Determine if the help in settings.doc is shown.
const show_help = ref(false);

const checkInt = (val: string) => Number.isInteger(val) || 'This must be an integer.';
const checkTimeDuration = (val: string) => isTimeDuration(val) || 'This must be a time duration.';

const valid_timezone = ref(true);

// Convert the time_duration to human readable format:
if (course_setting.value.type === 'time_duration') {
	time_duration_value.value = humanReadableTimeDuration(course_setting.value.value as number);
}

// These are for type list/multilist
if (course_setting.value.options) {
	options.value = course_setting.value.options.map((opt: string | OptionType) =>
		typeof opt === 'string' ? { label: opt, value: opt } : opt
	);
}
// Extract the option_value for type list
if (course_setting.value.type === 'list') {
	option_value.value = options.value.find((opt: OptionType) => opt.value === course_setting.value.value) ||
		{ value: '', label: '' };
}

// Extract the multilist_value for type list
if (course_setting.value.type === 'multilist') {
	multilist_value.value = options.value
		.filter((opt: OptionType) => (course_setting.value.value as string[]).includes(opt.value));
}

const updateCourseSetting = async () => {
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
};

watch(() => setting_value.value, async () => {
	if (setting_value.value) {
		if (course_setting.value.type === 'timezone') {
			// Check for valid timezone on the server.
			const response = await api.post('/global-settings/check-timezone',
				{ timezone: setting_value.value });
			valid_timezone.value = (response.data as { valid_timezone: boolean }).valid_timezone;
			if (!valid_timezone.value) return;
		}
		course_setting.value.value = setting_value.value;
		await updateCourseSetting();
	}
});

watch(() => option_value.value, async () => {
	if (option_value.value) {
		course_setting.value.value = option_value.value.value;
		await updateCourseSetting();
	}
});

watch(() => multilist_value.value, async () => {
	if (multilist_value.value) {
		course_setting.value.value = multilist_value.value.map(opt => opt.value);
		await updateCourseSetting();
	}
});

watch(() => time_duration_value.value, async () => {
	if (time_duration_value.value) {
		course_setting.value.value = convertTimeDuration(time_duration_value.value);
		await updateCourseSetting();
	}
});
</script>

<style lang="scss" scoped>
.helptext {
	border: 1px solid black;
	border-radius: 5px;
	padding: 5px 0;
	background-color: lightyellow;
}
</style>

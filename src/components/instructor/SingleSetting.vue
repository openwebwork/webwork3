<template>
	<tr>
		<td width="60%">{{ setting?.doc }}
			<q-icon v-if="setting?.doc2" name="help" class="q-ml-md">
				<q-tooltip class="text-body2">
					{{ setting.doc2 }}
				</q-tooltip>
			</q-icon>
		</td>
		<td width="40%">
			<input-with-blur
				outlined dense
				v-if="setting?.type === 'text' || setting?.type === 'timezone'"
				v-model="val"
			/>
			<q-select v-if="setting?.type === 'list'" v-model="option" :options="options" />
			<q-input v-if="setting?.type === 'time_duration'" v-model="val" :rules="check_time_dur" />
			<q-toggle v-if="setting?.type === 'boolean'" v-model="val" />
			<q-input v-if="setting?.type === 'integer'" v-model="val" :rules="check_int" />
		</td>
	</tr>
</template>

<script setup lang="ts">
import { defineProps, PropType, ref, watch } from 'vue';
import { CourseSetting, CourseSettingInfo, OptionType } from 'src/common/models/settings';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { useSettingsStore } from 'src/stores/settings';

const props = defineProps({
	setting: Object as PropType<CourseSettingInfo>,
	value: [String, Number, Boolean, Array]
});

const settings = useSettingsStore();
// The 'as string[]` is a hack since the array prop type cannot specify the
// the type of array.
const val = ref<string | number | boolean | string[]>(props.value);
const option = ref<OptionType>({ value: '', label: '' });
const options = ref<Array<OptionType>>([]);

if (props.setting?.options) {
	options.value = props.setting.options.map((opt: string | OptionType) =>
		typeof opt === 'string' ? { label: opt, value: opt } : opt
	);
	const v = options.value.find((opt: OptionType) => opt.value === val.value);
	option.value = v || { value: '', label: '' };
}

watch(() => val.value, () => {
	void settings.updateCourseSetting(new CourseSetting({
		var: props.setting?.var,
		value: val.value
	}));
});
</script>

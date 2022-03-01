<template>
	<tr>
		<td width="60%">{{ setting.doc }}
			<q-icon v-if="setting.doc2" name="help" class="q-ml-md">
				<q-tooltip class="text-body2">
					{{ setting.doc2 }}
				</q-tooltip>
			</q-icon>
		</td>
		<td width="40%">
			<input-with-blur
				outlined dense
				v-if="setting.type === 'text' || setting.type === 'timezone'"
				v-model="val"
			/>
			<q-select v-if="setting.type === 'list'" v-model="option" :options="options" />
			<q-input v-if="setting.type === 'time_duration'" v-model="val" :rules="check_time_dur" />
			<q-toggle v-if="setting.type === 'boolean'" v-model="val" />
			<q-input v-if="setting.type === 'integer'" v-model="val" :rules="check_int" />
		</td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, PropType, ref, watch } from 'vue';
import { CourseSetting, CourseSettingInfo, OptionType } from 'src/common/models/settings';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';
import { useSettingsStore } from 'src/stores/settings';

export default defineComponent({
	name: 'SingleSetting',
	components: {
		InputWithBlur
	},
	props: {
		setting: Object as PropType<CourseSettingInfo>,
		value: [String, Number, Boolean, Array]
	},
	setup(props) {
		const settings = useSettingsStore();
		// The 'as string[]` is a hack since the array prop type cannot specify the
		// the type of array.
		const val = ref<string | number | boolean | string[]>(props.value as string[]);
		const option = ref<OptionType>({ value: '', label: '' });
		const options = ref<Array<OptionType>>([]);

		if (props.setting?.options) {
			options.value = props.setting.options.map((opt: string | OptionType) =>
				typeof opt === 'string' ? { label: opt, value: opt } : opt
			);
			const v = options.value.find((opt: OptionType) => opt.value === val.value);
			option.value = v || { value: '', label: '' };
		}

		const time_dur_regexp = /^(\d+)\s(sec|second|min|minute|day|week|hr|hour)s?$/i;
		function isInt(val: string | number) {
			const value = typeof val === 'string' ? val : `${val}`;
			const match = /^(-?\d+)$/.exec(value);
			return match && parseInt(match[0]) >= -1;
		}

		watch(() => val.value, () => {
			void settings.updateCourseSetting(new CourseSetting({
				var: props.setting?.var,
				value: val.value
			}));
		});

		return {
			val,
			option,
			options,
			check_time_dur: [(val: string) => time_dur_regexp.test(val) || 'This is not a valid time duration'],
			check_int: [(val: string) => isInt(val) || 'This must be an integer greater than or equal to -1.']
		};
	}
});
</script>

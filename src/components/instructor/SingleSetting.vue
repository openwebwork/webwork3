<template>
	<tr>
		<td width="60%">{{ setting.doc }}</td>
		<td width="40%">
			<q-input outlined dense v-if="setting.type === 'text' || setting.type === 'timezone'" v-model="val" />
			<q-select v-if="setting.type === 'list'" v-model="option" :options="options" />
			<q-input v-if="setting.type === 'time_duration'" v-model="val" :rules="check_time_dur" />
			<q-toggle v-if="setting.type === 'boolean'" v-model="val" />
			<q-input v-if="setting.type === 'integer'" v-model="val" :rules="check_int" />
		</td>
	</tr>
</template>

<script lang="ts">
import { defineComponent, PropType, ref, Ref } from 'vue';
import { CourseSettingInfo, OptionType } from 'src/store/models';

export default defineComponent({
	name: 'SingleSetting',
	props: {
		setting: Object as PropType<CourseSettingInfo>,
		value: [String, Number, Boolean, Array]
	},
	setup(props) {
		const val = ref(props.value);
		const option: Ref<OptionType> = ref({ value: '', label: '' });
		const options: Ref<Array<OptionType>> = ref([]);
		if (props.setting && props.setting.options) {
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

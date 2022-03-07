<template>
	<q-input v-model="model_value" @blur="sendValue"/>
</template>

<script lang="ts">
import { logger } from 'src/boot/logger';
import { defineComponent, ref, watch } from 'vue';

export default defineComponent({
	name: 'InputWithBlur',
	props: {
		modelValue: {
			type: String,
			required: true
		}
	},
	emits: ['update:modelValue'],
	setup(props, { emit }) {
		const model_value = ref(props.modelValue);

		watch(() => props.modelValue, () => {
			logger.debug(`[InputWithBlur]: old value: ${model_value.value}`);
			model_value.value = props.modelValue;
			logger.debug(`[InputWithBlur]: new value: ${model_value.value}`);
		});

		return {
			model_value,
			sendValue: () => {
				emit('update:modelValue', model_value.value);
			}
		};
	}
});
</script>

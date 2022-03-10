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

		watch(() => props.modelValue, (new_str, old_str) => {
			logger.debug(`[InputWithBlur] parent has changed me from: ${old_str} to:${new_str}`);
			model_value.value = props.modelValue;
		});

		return {
			model_value,
			sendValue: () => {
				logger.debug('[InputWithBlur] My input has changed, telling parent.');
				emit('update:modelValue', model_value.value);
			}
		};
	}
});
</script>

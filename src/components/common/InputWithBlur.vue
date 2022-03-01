<template>
	<q-input v-model="model_value" @blur="sendValue"/>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';

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

		return {
			model_value,
			sendValue: () => {
				emit('update:modelValue', model_value.value);
			}
		};
	}
});
</script>

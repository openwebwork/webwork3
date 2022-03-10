<template>
	<div class="row q-pa-md">
		<q-field filled v-model="model_value" :error="!is_valid" :error-message="error_message">
			<template v-slot:control>
				<div class="self-center full-width no-outline" tabindex="0">{{model_string}}</div>
			</template>
			<template v-slot:append>
				<q-icon name="today" color="primary" size="sm">
					<q-popup-proxy transition-show="scale" transition-hide="scale">
						<div class="row items-center">
							<q-date v-model="model_string" mask="YYYY-MM-DD HH:mm" />
							<q-time v-model="model_string" mask="YYYY-MM-DD HH:mm" format24h/>
						</div>
					</q-popup-proxy>
				</q-icon>
			</template>
		</q-field>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, watch } from 'vue';
import { date } from 'quasar';
import { logger } from 'src/boot/logger';

export default defineComponent({
	name: 'DateTimeInput',
	props: {
		modelValue: {
			type: Number,
			required: true
		},
		errorMessage: {
			type: String,
			required: true
		}
	},
	emits: ['update:modelValue'],
	setup (props, { emit }) {
		const model_value = computed(() => props.modelValue);
		const model_string = ref<string>(date.formatDate((props.modelValue || Date.now()) * 1000, 'YYYY-MM-DD HH:mm'));
		const error_message = computed(() => props.errorMessage);
		const is_valid = computed(() => error_message.value === '');

		watch(() => model_string.value, () => {
			logger.debug('[DateTimeInput] model string has changed, telling parent.');
			emit('update:modelValue', date.extractDate(model_string.value, 'YYYY-MM-DD HH:mm').getTime() / 1000);
		});

		return {
			model_value,
			model_string,
			is_valid,
			error_message,
		};
	}
});
</script>

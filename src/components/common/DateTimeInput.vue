<template>
	<div class="row q-pa-md">
		<q-field filled>
			<template v-slot:control>
				<div class="self-center full-width no-outline" tabindex="0">{{date_time}}</div>
			</template>
			<template v-slot:append>
				<q-icon name="today" color="primary" size="sm">
					<q-popup-proxy transition-show="scale" transition-hide="scale">
						<div class="row items-center">
							<q-date v-model="model_date" mask="YYYY-MM-DD" />
							<q-time v-model="model_time" mask="HH:mm" format24h/>
						</div>
						<div class="row items-center justify-end">
							<q-btn v-close-popup label="Cancel" color="primary" flat />
							<q-btn label="Save" color="primary" flat @click="saveDateTime"/>
						</div>
					</q-popup-proxy>
				</q-icon>
			</template>
		</q-field>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { date } from 'quasar';

export default defineComponent({
	name: 'DateTimeInput',
	props: {
		modelValue: {
			type: Number,
			required: true
		},
		validation: {
			type: Array,
			required: true
		}
	},
	emits: ['update:modelValue'],
	setup (props, { emit }) {
		const model_date = ref<string>(date.formatDate((props.modelValue || Date.now()) * 1000, 'YYYY-MM-DD'));
		const model_time = ref<string>(date.formatDate((props.modelValue || Date.now()) * 1000, 'HH:mm'));
		const date_time = computed(() => `${model_date.value} ${model_time.value}`);

		return {
			model_date,
			model_time,
			date_time,
			rules: computed(() => props.validation as Array<(val: string)=>boolean>),
			saveDateTime: () => {
				const d = date.extractDate(date_time.value, 'YYYY-MM-DD HH:mm');
				emit('update:modelValue', d.getTime() / 1000);
			}
		};
	}
});
</script>

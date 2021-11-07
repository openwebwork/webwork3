<template>
	<div style="max-width: 300px">
		<q-input filled v-model="date_string" :rules="rules">
			<template v-slot:prepend>
				<q-icon name="event" class="cursor-pointer">
					<q-popup-proxy transition-show="scale" transition-hide="scale">
						<q-date v-model="date_string" mask="YYYY-MM-DD HH:mm">
							<div class="row items-center justify-end">
								<q-btn v-close-popup label="Close" color="primary" flat />
							</div>
						</q-date>
					</q-popup-proxy>
				</q-icon>
			</template>

			<template v-slot:append>
				<q-icon name="access_time" class="cursor-pointer">
					<q-popup-proxy transition-show="scale" transition-hide="scale">
						<q-time v-model="date_string" mask="YYYY-MM-DD HH:mm" format24h>
							<div class="row items-center justify-end">
								<q-btn v-close-popup label="Close" color="primary" flat />
							</div>
						</q-time>
					</q-popup-proxy>
				</q-icon>
			</template>
		</q-input>
	</div>
</template>

<script lang="ts">
import { defineComponent, watch, ref, computed } from 'vue';
import type { Ref } from 'vue';
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
		const date_string: Ref<string>
			= ref(date.formatDate((props.modelValue*1000 || Date.now()), 'YYYY-MM-DD HH:mm'));

		watch(
			() => date_string.value,
			(val) => {
				const d = date.extractDate(val, 'YYYY-MM-DD HH:mm');
				emit('update:modelValue', d.getTime() / 1000);
			}
		);
		return {
			date_string,
			rules: computed(() => props.validation as Array<(val: string)=>boolean>)
		};
	}
});
</script>

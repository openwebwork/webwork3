<template>
	<div class="q-pa-md" style="max-width: 300px">
		<q-input filled v-model="date_string">
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
import { defineComponent, watch, ref, Ref } from 'vue';
import { date } from 'quasar';

export default defineComponent({
	name: 'DateTimeInput',
	props: {
		modelValue: Number
		// type: Number,
		// required: true
	},
	emits: ['update:modelValue'],
	setup (props, { emit }) {
		const date_string: Ref<string> = ref(date.formatDate((props.modelValue || 0)*1000, 'YYYY-MM-DD HH:mm'));

		watch(
			() => date_string.value,
			(val) => {
				const d = date.extractDate(val, 'YYYY-MM-DD HH:mm');
				console.log(d.getTime());
				emit('update:modelValue', d.getTime());
			}
		);

		return {
			date_string
		};
	}
});
</script>

<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">Adding Users From a File</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				Click/Tap on the backdrop.
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="OK" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
	name: 'AddUsersFromFile',
	setup() {
		console.log('adding users');
	}
});
</script>
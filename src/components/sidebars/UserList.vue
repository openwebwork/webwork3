<template>
	<template v-for="user in users" :key="user.user_id">
		<q-item clickable @click="changeSet(user.user_id)">
			<q-item-section>{{ user.username }}</q-item-section>
		</q-item>
	</template>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useStore } from 'src/store';

export default defineComponent({
	name: 'ProblemSetList',
	setup() {
		const store = useStore();
		const router = useRouter();

		return {
			users: computed(() => store.state.users.users),
			changeSet: (set_id: number) => {
				void router.push({ name: 'ProblemSetDetails', params: { set_id: set_id } });
			}
		};
	}
});

</script>

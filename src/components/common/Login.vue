<template>
<div class='row q-mt-lg justify-center'>
	<q-card class='col-sm-4'>
		<q-form @submit.prevent='login'>
			<q-card-section>
				<div class='text-h6'>Login to WeBWorK</div>
			</q-card-section>
			<q-card-section>
				<q-input v-model='username' label='Username' />
				<q-input v-model='password' type='password' label='Password' />
			</q-card-section>
			<q-card-section>
				<q-btn push type='submit' color='primary' label='username' />
			</q-card-section>
			<q-card-section v-if='message'>
				<div class="text-red">{{message}}</div>
			</q-card-section>
		</q-form>
	</q-card>
</div>
</template>

<script lang='ts'>
import { useRouter } from 'vue-router';
import { defineComponent, ref } from 'vue';
import { useStore } from 'src/store';
import { checkPassword } from 'src/store/api';

export default defineComponent({
	name: 'username',
	setup() {
		const router = useRouter();
		const username = ref('');
		const password = ref('');
		const message = ref('');

		const store = useStore();
		const login = async () => {
			const username_info = {
				username: username.value,
				password: password.value
			};
			const session = await checkPassword(username_info);
			if (!session.logged_in) {
				message.value = session.message;
			} else { // success
				void store.dispatch('session/updateSessionInfo', session);
				if (session && session.user && session.user.is_admin) {
					void router.push('/admin');
				} else if (session && session.user && session.user.user_id) {
					void router.push(`/users/${session.user.user_id}/courses`);
				}
			}
		};
		return { username, password, message, login };
	}
});
</script>

<template>
<div class='fit row wrap justify-center items-start content-start'>
	<q-card class='col-4'>
		<q-card-section>
			<div class='text-h6'>Login to WeBWorK</div>
		</q-card-section>
		<q-card-section v-if='message.length>0'>
			<div>{{message}}</div>
		</q-card-section>
		<q-card-section>
			<q-input v-model='email' label='Email'/>
			<q-input v-model='password' type='password' label='Password'/>
		</q-card-section>
		<q-card-section>
			<q-btn push color='primary' label='Login' @click='login' />
		</q-card-section>
	</q-card>
</div>
</template>


<script lang='ts'>
import { useStore } from '../../store';
import { useRouter } from 'vue-router';
import { defineComponent, ref, Ref } from 'vue';

import { checkPassword } from '../../store/api';

export default defineComponent({
	name: 'Login',
	setup() {
		const router = useRouter();
		const email: Ref<string> = ref('');
		const password: Ref<string> = ref('');
		const message: Ref<string> = ref('');

		const store = useStore();
		return {
			email,
			password,
			message,
			login: async () => {
				const login_info = {
					email: email.value,
					password: password.value
				};
				const session = await checkPassword(login_info);
				if (!session.logged_in) {
					message.value = session.message;
				} else { // success
					void store.dispatch('session/updateSessionInfo',session);
					if (session && session.user && session.user.is_admin) {
						void router.push('/webwork3/admin');
					} else if (session && session.user && session.user.user_id) {
						void router.push(`/webwork3/users/${session.user.user_id}/courses`);
					}
				}
			}
		};
	}
});
</script>

<style>
</style>

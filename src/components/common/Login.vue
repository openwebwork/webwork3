<template>
<div class="fit row wrap justify-center items-start content-start">
	<q-card class="col-4">
		<q-card-section>
			<div class="text-h6">Login to WeBWorK</div>
		</q-card-section>
		<q-card-section v-if="message.length>0">
			<div>{{message}}</div>
		</q-card-section>
		<q-card-section>
			<q-input v-model="email" label="Email"/>
			<q-input v-model="password" type="password" label="Password"/>
		</q-card-section>
		<q-card-section>
			<q-btn push color="primary" label="Login" @click="login" />
		</q-card-section>
	</q-card>
</div>
</template>


<script lang="ts">
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { defineComponent, ref, Ref } from 'vue';

import { checkPassword } from "@/store/api";

export default defineComponent({
	name: 'Login',
	setup() {
		const router = useRouter();
		const email: Ref<string> = ref("");
		const password: Ref<string> = ref("");
		let message: Ref<string> = ref("");

		const store = useStore()

		const login = async () => {
			const login_info = await checkPassword({email: email.value, password: password.value});
			if (!login_info.logged_in) {
				message.value = login_info.message;
			} else { // success
				store.dispatch("session/updateLoginInfo",login_info);
				router.push(`/webwork3/users/${login_info.user.user_id}/courses`);
			}
		};
		return { email, password, message,login};
	}
});
</script>

<style>
</style>

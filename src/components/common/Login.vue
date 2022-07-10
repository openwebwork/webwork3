<template>
	<div class="row q-mt-lg justify-center">
		<q-card class="col-sm-4">
			<q-form @submit.prevent="login">
				<q-card-section>
					<div class="text-h6">Login to WeBWorK</div>
				</q-card-section>
				<q-card-section>
					<q-input v-model="username" label="Username" />
					<q-input v-model="password" type="password" label="Password" />
				</q-card-section>
				<q-card-section>
					<q-btn push type="submit" color="primary" label="Login" />
				</q-card-section>
				<q-card-section v-if="message">
					<div class="text-red">{{ message }}</div>
				</q-card-section>
			</q-form>
		</q-card>
	</div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { checkPassword } from 'src/common/api-requests/session';
import { useSessionStore } from 'src/stores/session';
import { usePermissionStore } from 'src/stores/permissions';

const router = useRouter();
const username = ref('');
const password = ref('');
const message = ref('');
const i18n = useI18n({ useScope: 'global' });

const session = useSessionStore();
const permission_store = usePermissionStore();

if (session && session.logged_in && session.user) {
	if (session.user.is_admin) {
		void router.push('/admin');
	} else if (session.user.user_id) {
		void router.push(`/users/${session.user.user_id}/courses`);
	}
}

const login = async () => {
	const username_info = {
		username: username.value,
		password: password.value
	};
	const session_info = await checkPassword(username_info);
	if (!session_info.logged_in) {
		message.value = i18n.t('authentication.failure');
	} else {
		// success
		session.updateSessionInfo(session_info);

		await permission_store.fetchRoles();
		await permission_store.fetchRoutePermissions();

		if (session_info?.user?.is_admin) {
			void router.push('/admin');
		} else if (session && session.user && session.user.user_id) {
			void router.push(`/users/${session.user.user_id}/courses`);
		}
	}
};
</script>

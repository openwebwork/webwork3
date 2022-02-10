<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'src/store';
import { setI18nLanguage } from 'boot/i18n';
import { logger } from 'boot/logger';

export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	setup(props) {
		const store = useStore();

		if (props.course_id && props.course_name) {
			const course = {
				course_id: props.course_id,
				course_name: props.course_name
			};
			void store.dispatch('session/setCourse', course);
		}
	},
	async created() {
		// fetch most data needed for instructor views
		const store = useStore();
		const route = useRoute();
		logger.debug('[Intructor]: fetching data from the server.');
		await store.dispatch('users/fetchMergedUsers', route.params.course_id);
		await store.dispatch('problem_sets/fetchProblemSets', route.params.course_id);
		await store.dispatch('settings/fetchDefaultSettings');
		logger.debug('[Intructor]: fetching course settings from the server.');
		await store.dispatch('settings/fetchCourseSettings', route.params.course_id);
		logger.debug('[Intructor]: finished fetching data.');

		// Set the language from the course settings.
		await setI18nLanguage((store.getters as { [key: string]: (var_name: string) => string })
			['settings/get_setting_value']('language'));
	}
});
</script>

<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useRoute } from 'vue-router';
import { setI18nLanguage } from 'boot/i18n';
import { logger } from 'boot/logger';

import { useUserStore } from 'src/stores/users';
import { useSettingsStore } from 'src/stores/settings';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSessionStore } from 'src/stores/session';
import { parseRouteCourseID } from 'src/router/utils';

export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	setup(props) {
		const session = useSessionStore();

		if (props.course_id && props.course_name) {
			const course = {
				course_id: parseInt(props.course_id),
				course_name: props.course_name
			};
			void session.setCourse(course);
		}
	},
	async created() {
		// fetch most data needed for instructor views
		const users = useUserStore();
		const settings = useSettingsStore();
		const problem_sets = useProblemSetStore();
		const route = useRoute();

		const course_id = parseRouteCourseID(route);

		logger.debug('[Intructor]: fetching users from the server.');
		await users.fetchMergedUsers(course_id);

		logger.debug('[Instructor]: fetch problem_sets from server');
		await problem_sets.fetchProblemSets(course_id);

		logger.debug('[Intructor]: fetch settings from the server.');
		await settings.fetchDefaultSettings();
		await settings.fetchCourseSettings(course_id);

		// Set the language from the course settings.

		await setI18nLanguage(settings.getCourseSetting('language').value as string);

	}
});
</script>

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
	setup() {
		const session = useSessionStore();
		const users = useUserStore();
		const route = useRoute();

		const course_id = parseRouteCourseID(route);
		const course = users.user_courses.find(c => c.course_id === course_id);
		if (course) {
			void session.setCourse({
				course_id,
				course_name: course.course_name
			});
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

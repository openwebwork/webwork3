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

// Eventually we'll switch to a script set-up block, but seems to be still
// experimental/beta https://vuejs.org/api/sfc-script-setup.html#top-level-await

export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	async setup() {
		const session = useSessionStore();
		const users = useUserStore();
		const settings = useSettingsStore();
		const problem_sets = useProblemSetStore();
		const route = useRoute();

		const course_id = parseRouteCourseID(route);
		const course = session.user_courses.find(c => c.course_id === course_id);
		if (course) {
			session.setCourse({
				course_id,
				course_name: course.course_name
			});
		} else {
			logger.warn(`Can't find ${course_id} in ${session.user_courses
				.map((c) => c.course_id).join(', ')}`);
		}
		await users.fetchGlobalCourseUsers(course_id);
		await users.fetchCourseUsers(course_id);
		await problem_sets.fetchProblemSets(course_id);
		await settings.fetchDefaultSettings(course_id)
			.then(() => settings.fetchCourseSettings(course_id))
			.then(() => void setI18nLanguage(settings.getCourseSetting('language').value as string))
			.catch((err) => logger.error(`${JSON.stringify(err)}`));

	},
});
</script>

<template>
	<suspense>
		<router-view />
	</suspense>
</template>

<!-- Switched to a script setup block, which was needed to fix a number of errors.
To use async within script setup, the router-view needs to be wrapped in a
suspense tag.

Note as of aug-2022, this is still
experimental/beta https://vuejs.org/api/sfc-script-setup.html#top-level-await
-->

<script setup lang="ts">
import { useRoute } from 'vue-router';
import { setI18nLanguage } from 'boot/i18n';
import { logger } from 'boot/logger';

import { useUserStore } from 'src/stores/users';
import { useSettingsStore } from 'src/stores/settings';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useSessionStore } from 'src/stores/session';
import { parseRouteCourseID } from 'src/router/utils';

const session = useSessionStore();
const users = useUserStore();
const settings = useSettingsStore();
const problem_sets = useProblemSetStore();
const route = useRoute();

const course_id = parseRouteCourseID(route);

// allow the route to update the session's 'selected' course
if (course_id !== session.course.course_id) {
	session.setCourse(course_id);
}

await users.fetchGlobalCourseUsers(course_id);
await users.fetchCourseUsers(course_id);
await problem_sets.fetchProblemSets(course_id);
await settings.fetchDefaultSettings(course_id)
	.then(() => settings.fetchCourseSettings(course_id))
	.then(() => void setI18nLanguage(settings.getCourseSetting('language').value as string))
	.catch((err) => logger.error(`${JSON.stringify(err)}`));

</script>

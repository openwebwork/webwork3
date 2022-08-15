<template>
	<router-view />
</template>

<script setup lang="ts">
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useUserStore } from 'src/stores/users';
import { useRoute } from 'vue-router';
import { logger } from 'boot/logger';
import { parseRouteCourseID } from 'src/router/utils';
import { watch } from 'vue';

const session_store = useSessionStore();
const user_store = useUserStore();
const problem_set_store = useProblemSetStore();
const route = useRoute();

//
const loadStudentSets = async () => {
	// Fetch only the current user info.
	await user_store.setSessionUser();

	logger.debug(`[Student/loadStudentSets]: loading data for course ${session_store.course.course_id}`);

	if (session_store.course.course_id > 0) {
		// Fetch all problem sets and user sets
		await problem_set_store.fetchProblemSets(session_store.course.course_id);
		if (session_store.user.user_id) {
			await problem_set_store.fetchUserSetsForUser({ user_id: session_store.user.user_id });
		}
	}
};

const course_id = parseRouteCourseID(route);
const course = session_store.user_courses.find(c => c.course_id === course_id);
if (course) {
	session_store.setCourse({
		course_id: course_id,
		course_name: course.course_name ?? 'unknown'
	});
} else {
	logger.warn(`Can't find ${course_id} in ${session_store.user_courses
		.map((c) => c.course_id).join(', ')}`);
}
await loadStudentSets();

watch(() => session_store.course.course_id, async () => {
	await loadStudentSets();
});
</script>

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

const session = useSessionStore();
const users = useUserStore();
const problem_set_store = useProblemSetStore();
const route = useRoute();
const course_id = parseRouteCourseID(route);
if (session.user.user_id) await users.fetchUserCourses(session.user.user_id)
	.then(() => {
		const course = users.user_courses.find(c => c.course_id === course_id);
		if (course) {
			session.setCourse({
				course_id,
				course_name: course.course_name
			});
		} else {
			logger.warn(`Can't find ${course_id} in ${users.user_courses.map((c) => c.course_id).join(', ')}`);
		}
	});

await problem_set_store.fetchProblemSets(parseRouteCourseID(route));
</script>

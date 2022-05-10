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
import { useSetProblemStore } from 'src/stores/set_problems';

const session = useSessionStore();
const user_store = useUserStore();
const problem_set_store = useProblemSetStore();
const set_problem_store = useSetProblemStore();
const route = useRoute();
const course_id = parseRouteCourseID(route);
if (session.user.user_id) await session.fetchUserCourses(session.user.user_id)
	.then(async () => {
		const course = session.user_courses.find(c => c.course_id === course_id);
		if (course) {
			session.setCourse({
				course_id,
				course_name: course.course_name
			});
			// Fetch only the current user info.
			await user_store.setSessionUser();

			// Fetch all problem sets and user sets
			void problem_set_store.fetchProblemSets(course_id);
			void problem_set_store.fetchUserSetsForUser({ user_id: session.user.user_id });

			// Fetch problems and user problems.
			void set_problem_store.fetchSetProblems(course_id);
			void set_problem_store.fetchUserProblemsForUser(session.user.user_id);
		} else {
			logger.warn(`Can't find ${course_id} in ${session.user_courses.map((c) => c.course_id).join(', ')}`);
		}
	});
</script>

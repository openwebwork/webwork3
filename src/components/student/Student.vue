<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useSessionStore } from 'src/stores/session';
import { useProblemSetStore } from 'src/stores/problem_sets';
import { useUserStore } from 'src/stores/users';
import { useRoute } from 'vue-router';
import { parseRouteCourseID } from 'src/router/utils';
import { parseNonNegInt } from 'src/common/models/parsers';

export default defineComponent({
	name: 'Student',
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
	created() {
		const problem_sets = useProblemSetStore();
		const session = useSessionStore();
		void problem_sets.fetchUserMergedUserSets(parseNonNegInt(session.user.user_id ?? 0));
		void problem_sets.fetchMergedUserProblems(parseNonNegInt(session.user.user_id ?? 0));
		void problem_sets.fetchSetProblems();
	}
});
</script>

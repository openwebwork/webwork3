<template>
<div class="q-pa-md">
	<div class="row" v-if="user !== undefined">
		<h3> Welcome {{user.first_name}} {{user.last_name}} </h3>
	</div>

	<div class="row">
		<p>Select a course below:</p>
	</div>
	<div class="q-pa-md row items-start q-gutter-md">
		<div v-for="info in course_types" :key="info.name">
			<q-card v-if="info.courses.length > 0">
				<q-card-section>
					<div class="text-h4">Courses as a {{ info.name }}</div>
				</q-card-section>
				<div class="q-pa-md">
					<q-card-section>
						<q-list>
							<template v-for="course in info.courses" :key="course.course_id">
								<q-item>
									<q-btn outline color="primary" @click="switchCourse(course.course_id)"
										:label="course.course_name" />
									</q-item>
							</template>
						</q-list>
					</q-card-section>
				</div>
			</q-card>
		</div>
	</div>
</div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';

import { useSessionStore } from 'src/stores/session';
import { logger } from 'src/boot/logger';

const session_store = useSessionStore();
const router = useRouter();

const user = computed(() => session_store.user);

// This is used to simplify the UI.
const course_types = computed(() => [
	{ name: 'Student', courses: session_store.user_courses.filter(c => c.role === 'student') },
	{ name: 'Instructor', courses: session_store.user_courses.filter(c => c.role === 'instructor') }
]);

const switchCourse = (course_id?: number) => {
	if (!course_id) {
		logger.error('[UserCourses/switchCourse]: the course_id is 0 or undefined.');
		return;
	}
	session_store.setCourse(course_id);

	if (session_store.course.role === 'student') {
		void router.push({
			name: 'StudentDashboard',
			params: { course_id }
		});
	} else if (session_store.course.role === 'instructor') {
		void router.push({
			name: 'InstructorDashboard',
			params: { course_id }
		});
	}
};

</script>

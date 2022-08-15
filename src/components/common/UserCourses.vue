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

const user_courses = computed(() => session_store.user_courses);

const user = computed(() => session_store.user);

// This is used to simplify the UI.
const course_types = computed(() => [
	{ name: 'Student', courses: user_courses.value.filter(c => c.role == 'student') },
	{ name: 'Instructor', courses: session_store.instructor_user_courses }
]);

const switchCourse = async (course_id?: number) => {
	if (course_id == undefined || course_id === 0) {
		logger.error('[UserCourses/switchCourse]: the course_id is 0 or undefined.');
	}
	const student_course = session_store.student_user_courses.find(c => c.course_id === course_id);
	const instructor_course = session_store.instructor_user_courses.find(c => c.course_id === course_id);
	if (student_course) {
		session_store.setCourse({
			course_name: student_course.course_name ?? 'unknown',
			course_id: student_course.course_id ?? 0,
			role: 'student'
		});
		await router.push({
			name: 'StudentDashboard',
			params: { course_id: student_course.course_id }
		});
	} else if (instructor_course) {
		session_store.setCourse({
			course_name: instructor_course.course_name ?? 'unknown',
			course_id: instructor_course.course_id ?? 0,
			role: 'instructor'
		});
		await router.push({
			name: 'InstructorDashboard',
			params: { course_id: instructor_course.course_id }
		});
	}
};

</script>

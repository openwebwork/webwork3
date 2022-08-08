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

const session = useSessionStore();
const router = useRouter();

// This is used to simplify the UI.
const course_types = computed(() => [
	{ name: 'Student', courses: student_courses.value },
	{ name: 'Instrutor', courses: instructor_courses.value }
]);

const student_courses = computed(() =>
	// for some reason on load the user_course.role is undefined.
	session.user_courses.filter(user_course => user_course.role === 'student'));

const instructor_courses = computed(() =>
	// For some reason on load the user_course.role is undefined.
	session.user_courses.filter(user_course => user_course.role === 'instructor')
);
const user = computed(() => session.user);

const switchCourse = async (course_id: number) => {
	const student_course = student_courses.value.find(c => c.course_id === course_id);
	const instructor_course = instructor_courses.value.find(c => c.course_id === course_id);
	if (student_course) {
		session.setCourse({
			course_name: student_course.course_name,
			course_id: student_course.course_id,
			role: 'student'
		});
		await router.push({
			name: 'StudentDashboard',
			params: { course_id: student_course.course_id }
		});
	} else if (instructor_course) {
		session.setCourse({
			course_name: instructor_course.course_name,
			course_id: instructor_course.course_id,
			role: 'instructor'
		});
		await router.push({
			name: 'instructor',
			params: { course_id: instructor_course.course_id }
		});
	}
};

</script>

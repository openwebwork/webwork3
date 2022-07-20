<template>
<div class="q-pa-md">
	<div class="row" v-if="user !== undefined">
		<h3> Welcome {{user.first_name}} {{user.last_name}} </h3>
	</div>

	<div class="row">
		<p>Select a course below:</p>
	</div>
	<div class="q-pa-md row items-start q-gutter-md">
		<q-card v-if="student_courses.length > 0">
			<q-card-section>
				<div class="text-h4">Courses as a Student</div>
			</q-card-section>
			<div class="q-pa-md">
				<q-card-section>
					<q-list>
						<template v-for="course in student_courses" :key="course.course_id">
							<q-item
								:to="{
									name: 'StudentDashboard',
									params: { course_id: course.course_id, course_name: course.course_name }
									}"
								>
								<q-item-section>
									<q-item-label>{{ course.course_name }}</q-item-label>
								</q-item-section>
							</q-item>
						</template>
					</q-list>
				</q-card-section>
			</div>
		</q-card>
		<q-card v-if="instructor_courses.length > 0">
			<q-card-section>
				<div class="text-h4">Courses as an Instructor</div>
			</q-card-section>
			<div class="q-pa-md">
				<q-card-section>
					<q-list>
						<template v-for="course in instructor_courses" :key="course.course_id">
							<q-item
								:to="{
									name: 'InstructorDashboard',
									params: { course_id: course.course_id }
								}">
								<q-item-section>
									<q-item-label>{{ course.course_name }}</q-item-label>
								</q-item-section>
							</q-item>
						</template>
					</q-list>
				</q-card-section>
			</div>
		</q-card>
	</div>
</div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useSessionStore } from 'src/stores/session';
import { parseNonNegInt, parseUserRole } from 'src/common/models/parsers';

const session = useSessionStore();
// fetch the data when the view is created and the data is already being observed
if (session) await session.fetchUserCourses(parseNonNegInt(session.user.user_id));

const student_courses = computed(() =>
	// for some reason on load the user_course.role is undefined.  The ?? '' prevents an error.
	session.user_courses.filter(user_course => parseUserRole(user_course.role ?? '') === 'STUDENT'));

const instructor_courses = computed(() =>
	session.user_courses.filter(user_course => parseUserRole(user_course.role ?? '') === 'INSTRUCTOR')
);
const user = computed(() => session.user);

</script>

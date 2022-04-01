<template>
<div class="q-pa-md">
	<div class="row" v-if="user !== undefined">
		<h3> Welcome {{user.first_name}} {{user.last_name}} </h3>
	</div>

	<div class="row">
		<p>Select a course below:</p>
	</div>
	<div class="q-pa-md row items-start q-gutter-md">
		<q-card>
			<q-card-section>
				<div class="text-h4">Courses as a Student</div>
			</q-card-section>
			<div class="q-pa-md">
				<q-card-section>
					<q-list>
						<template v-for="course in student_courses" :key="course.course_id">
							<q-item
								:to="{
									name: 'student',
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
		<q-card>
			<q-card-section>
				<div class="text-h4">Courses as an Instructor</div>
			</q-card-section>
			<div class="q-pa-md">
				<q-card-section>
					<q-list>
						<template v-for="course in instructor_courses" :key="course.course_id">
							<q-item
								:to="{
									name: 'instructor',
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

<script lang="ts">
import { defineComponent, computed } from 'vue';
import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import { parseNonNegInt } from 'src/common/models/parsers';

export default defineComponent({
	name: 'UserCourses',
	setup() {
		const users = useUserStore();
		const session = useSessionStore();
		return {
			student_courses: computed(() =>
				users.user_courses.filter(user_course => user_course.role === 'student')
			),
			instructor_courses: computed(() =>
				users.user_courses.filter(user_course => user_course.role === 'instructor')
			),
			user: computed(() => session.user)
		};
	},
	created() {
		// fetch the data when the view is created and the data is
		// already being observed
		const users = useUserStore();
		const session = useSessionStore();
		void users.fetchUserCourses(parseNonNegInt(session.user.user_id ?? 0));
	}
});
</script>

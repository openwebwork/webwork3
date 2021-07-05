<template>
	<div class="row" v-if="user !== undefined">
			<h3> Welcome {{user.first_name}} {{user.last_name}} </h3>
	</div>
	<div class="row">
		<p> Select a course below: </p>
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
						<!-- <q-item :to="{path: '/webwork3/courses/' + course.course_id}"> -->
						<q-item :to="{name: 'student', params: {course_id: course.course_id, course_name: course.course_name}}">
							<q-item-section>
								<q-item-label>{{course.course_name}}</q-item-label>
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
						<q-item :to="{name: 'instructor', params: {course_id: course.course_id, course_name: course.course_name}}">
							<q-item-section>
								<q-item-label>{{course.course_name}}</q-item-label>
							</q-item-section>
						</q-item>
					</template>
				</q-list>
			</q-card-section>
		</div>
	</q-card>
	</div>
</template>


<script lang="ts">
import { defineComponent, computed } from 'vue';
// import { defineComponent } from 'vue';
import { useStore } from 'vuex';

import { CourseUser }  from '@/store/models';

export default defineComponent({
	name: 'Test',
	setup() {
		const store = useStore();
		return {
			student_courses: computed(() => {
				return store.getters['user/user_courses'].filter( (user: CourseUser) => user.role === 'student');
				}),
			instructor_courses: computed(() => {
				return store.getters['user/user_courses'].filter( (user: CourseUser) => user.role === 'instructor');
				}),
			user: computed( () => {
				console.log(store.getters['session/user']);
				return store.getters['session/user'];
			})
		};
	},

	async created () {
		console.log("in created");
    // fetch the data when the view is created and the data is
    // already being observed
		const store = useStore();
		const user = store.getters["session/user"];
		await store.dispatch("user/fetchUserCourses",user.user_id);
  },
});

</script>
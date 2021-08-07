<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">New Course</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row q-col-gutter-lg">
					<div class="col-3">
						<q-input outlined v-model="course.course_name" label="Course Name" />
					</div>
					<div class="col">
						<div class="text-h5">Add Instructor </div>
					</div>
				</div>
				<div class="row">
					<div class="col-3">
						<q-toggle v-model="course.visible" label="Visible" />
					</div>
					<div class="col-3">
						<q-input outlined v-model="user.login" label="Instructor Login" @blur="checkUser"/>
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-date v-model="course_dates" title="Course Dates" range />
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Add This User and Another One" @click="addUser" />
				<q-btn flat label="Add This User and Close" @click="addUser" />
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from '../../store';
import { newCourse, newUser } from '../../store/common';

import { Course, ResponseError, User } from '../../store/models';
import { AxiosError } from 'axios';

interface DateRange {
	to: string;
	from: string;
}

export default defineComponent({
	name: 'NewCourseDialog',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const store = useStore();

		const course: Ref<Course> = ref(newCourse());
		const user: Ref<User> = ref(newUser());
		const login: Ref<string> = ref('');
		const course_dates: Ref<DateRange> = ref({to:'',from:''});

		return {
			course,
			user,
			login,
			course_dates,
			checkUser: async () => { // lookup the user by login to see if already exists
				const _user = await store.dispatch('user/getUser',login.value);

			},
			addCourse: async () => {
				try {
					const _course = await store.dispatch('courses/addCourse',course.value) as unknown as Course;
					$q.notify({
						message: `The user ${_course.course_name} was successfully added to the course.`,
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					const data = error  && error.response && (error.response.data  as ResponseError) || { exception: ''};
					$q.notify({
						// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
						message: data.exception,
						color: 'red'
					});
				}
			}
		}
	}
});
</script>
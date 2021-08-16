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
						<div class="text-h5">Add Instructor</div>
					</div>
				</div>
				<div class="row">
					<div class="col-3">
						<q-toggle v-model="course.visible" label="Visible" />
					</div>
					<div class="col-3">
						<q-input outlined v-model="user.username" label="Instructor username" @blur="checkUser" />
					</div>
				</div>
				<div class="row q-col-gutter-lg">
					<div class="col-3">
						<q-date v-model="course_dates" title="Course Dates" range />
					</div>
					<div class="col">
						<div class="row q-col-gutter-lg">
							<div class="col-3">
								<q-input outlined :disable="instructor_exists"
									v-model="user.first_name" label="First Name" />
							</div>
							<div class="col-3">
								<q-input outlined :disable="instructor_exists"
									v-model="user.last_name" label="Last Name" />
							</div>
						</div>
						<div class="row q-col-gutter-lg">
							<div class="col-3">
								<q-input outlined :disable="instructor_exists"
									v-model="user.email" label="Email" />
							</div>
						</div>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-blue">
				<q-btn flat label="Add This Course and Close" @click="addCourse" />
				<q-btn flat label="Cancel" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from '../../store';
import { newCourse, newCourseUser, newUser } from '../../store/common';

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
		const username: Ref<string> = ref('');
		const instructor_exists = ref(false);
		const course_dates: Ref<DateRange> = ref({ to: '', from: '' });

		return {
			course,
			user,
			username,
			course_dates,
			instructor_exists,
			checkUser: async () => {
				// lookup the user by username to see if already exists
				const _user = (await store.dispatch('users/getGlobalUser', user.value.username)) as User;
				console.log(_user);
				if (_user !== undefined) {
					user.value = _user;
					instructor_exists.value = true;
				} else {
					instructor_exists.value = false;
				}
			},
			addCourse: async () => {
				try {
					const _course = (await store.dispatch('courses/addCourse', course.value)) as unknown as Course;

					$q.notify({
						message: `The course ${_course.course_name} was successfully added.`,
						color: 'green'
					});
					if (!instructor_exists.value) {
						// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
						void (await store.dispatch('users/addGlobalUser', user.value));
					}
					// add the user to the course
					const _course_user = newCourseUser();
					_course_user.role = 'instructor';
					_course_user.course_id = _course.course_id;
					await store.dispatch('users/addCourseUser', _course_user);
					$q.notify({
						message: `The user ${user.value.username} was successfully added to the course.`,
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					const data = (error && error.response && (error.response.data as ResponseError))
						|| { exception: '' };
					$q.notify({
						// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
						message: data.exception,
						color: 'red'
					});
				}
			}
		};
	}
});
</script>

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
import { defineComponent, ref } from 'vue';
import { useQuasar } from 'quasar';

import { useCourseStore } from 'src/stores/courses';

import { Course } from 'src/common/models/courses';
import { ResponseError } from 'src/common/api-requests/interfaces';
import { User, CourseUser } from 'src/common/models/users';
import { AxiosError } from 'axios';
import { useUserStore } from 'src/stores/users';

interface DateRange {
	to: string;
	from: string;
}

export default defineComponent({
	name: 'NewCourseDialog',
	emits: ['closeDialog'],
	setup(props, context) {
		const $q = useQuasar();
		const courses = useCourseStore();
		const users = useUserStore();

		const course = ref<Course>(new Course());
		const user = ref<User>(new User());
		const username = ref<string>('');
		const instructor_exists = ref(false);
		const course_dates = ref<DateRange>({ to: '', from: '' });

		return {
			course,
			user,
			username,
			course_dates,
			instructor_exists,
			checkUser: async () => {
				// lookup the user by username to see if already exists
				const _user = (await users.getUser(user.value.username));
				if (_user !== undefined) {
					user.value = new User(_user);
					instructor_exists.value = true;
				} else {
					instructor_exists.value = false;
				}
			},
			addCourse: async () => {
				try {
					const added_course = (await courses.addCourse(course.value as Course));
					$q.notify({
						message: `The course '${added_course.course_name || ''}' was successfully added.`,
						color: 'green'
					});
					if (!instructor_exists.value) {
						// eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
						void users.addUser(user.value as User);
					}
					// add the user to the course
					const course_user = new CourseUser({});
					course_user.role = 'instructor';
					course_user.course_id = added_course.course_id;
					await users.addCourseUser(course_user);
					$q.notify({
						message: `The user ${user.value.username ?? ''} was successfully added to the course.`,
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					const data = error?.response?.data as ResponseError || { exception: '' };
					$q.notify({
						message: data.exception,
						color: 'red'
					});
				}
			}
		};
	}
});
</script>

<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">New Course</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row q-col-gutter-lg">
					<div class="col-3">
						<q-input outlined v-model="course.course_name" label="Course Name" @blur="checkCourse"/>
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
						<q-input outlined v-model="username" label="Instructor username" @blur="checkUser" />
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
							<div class="col-6">
								<input-with-blur outlined :disable="instructor_exists"
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
import { defineComponent, ref, watch } from 'vue';
import { useQuasar, date } from 'quasar';
import { useCourseStore } from 'src/stores/courses';
import { useUserStore } from 'src/stores/users';
import { Course } from 'src/common/models/courses';
import { User, CourseUser } from 'src/common/models/users';
import { logger } from 'src/boot/logger';
import InputWithBlur from 'src/components/common/InputWithBlur.vue';

interface DateRange {
	to: string;
	from: string;
}

export default defineComponent({
	name: 'NewCourseDialog',
	emits: ['closeDialog'],
	components: {
		InputWithBlur
	},
	setup(props, context) {
		const $q = useQuasar();
		const courses = useCourseStore();
		const users = useUserStore();

		const course = ref<Course>(new Course({ course_name: 'New Course' }));
		const user = ref<User>(new User({ username: 'new_professor' }));

		// modify username without editing the User
		const username = ref<string>('');
		const instructor_exists = ref(false);
		const course_dates = ref<DateRange>({ to: '', from: '' });

		logger.debug('[AddCourse] dialog opened.');

		watch(() => course_dates, () => {
			const start = date.extractDate(course_dates.value.from, 'YYYY/MM/DD').getTime() / 1000;
			const end = date.extractDate(course_dates.value.to, 'YYYY/MM/DD').getTime() / 1000;
			course.value.setDates({ start, end });
			logger.debug(`[AddCourse/updateDates] start: ${start} end: ${end}`);
		}, { deep: true });

		const checkCourse = () => {
			logger.debug('[AddCourse/checkCourse] The course name changed, checking for uniqueness.');
			if (courses.getCourseByName(course.value.course_name)) {
				logger.debug(`[AddCourse/checkCourse] A course named ${course.value.course_name} already exists.`);
				$q.notify({
					message: `A course named ${course.value.course_name} already exists.`,
					color: 'red'
				});
			}
		};

		const addCourse = async () => {
			let course_instructor: User | undefined;

			// add global user for instructor if they don't exist yet
			if (!instructor_exists.value) {
				// unclear why user.value must be re-cast...
				course_instructor = await users.addUser(user.value as User)
					.then((_new_user) => {
						if (!_new_user) {
							logger.error('[AddCourse/addCourse] requested addUser, empty response. TSNH!');
							$q.notify({
								message: 'An unexpected error occurred, please try again.',
								color: 'red'
							});
						} else {
							logger.debug(`[AddCourse/addCourse] Instructor ${_new_user.username} added as new user!`);
							$q.notify({
								message: `'${_new_user.username}' was successfully created.`,
								color: 'green'
							});
							return _new_user;
						}
					})
					.catch((e: Error) => {
						logger.error(`[AddCourse/addCourse] Failed to add ${JSON.stringify(user.value)}: ${
							JSON.stringify(e)}.`);
						throw e;
					});
			} else {
				logger.debug(`[AddCourse/addCourse] ${user.value.username} already exists, skip to new course.`);
				course_instructor = user.value as User;
			}
			if (!course_instructor) return;

			// create the new course
			const new_course = await courses.addCourse(course.value as Course)
				.then((_new_course) => {
					if (!_new_course) {
						logger.error('[AddCourse] requested addCourse, empty response. TSNH!');
						$q.notify({
							message: 'An unexpected error occurred, please try again.',
							color: 'red'
						});
					} else {
						logger.debug(`[AddCourse/addCourse] ${_new_course.course_name} added!`);
						$q.notify({
							message: `The course '${_new_course.course_name}' was successfully added.`,
							color: 'green'
						});
						return _new_course;
					}
				})
				.catch((e: Error) => {
					logger.error(`[AddCourse/addCourse] Failed to add ${JSON.stringify(course.value)}: ${
						JSON.stringify(e)}.`);
					throw e;
				});
			if (!new_course) return;

			// add the user to the course as instructor
			await users.addCourseUser(new CourseUser({
				role: 'INSTRUCTOR',
				user_id: course_instructor.user_id,
				course_id: new_course.course_id,

			}))
				.then((_course_user) => {
					if (!_course_user) logger.error('[AddCourse] requested new CourseUser, empty response. TSNH!');
					logger.debug('[AddCourse/addCourse] successfully added course_user.');
				})
				.catch((e: Error) => {
					logger.error(JSON.stringify(e));
					throw e;
				});

			context.emit('closeDialog');
		};

		return {
			course,
			user,
			username,
			course_dates,
			instructor_exists,
			checkCourse,
			checkUser: async () => {
				// lookup the user by username to see if already exists
				await users.getUser(username.value)
					.then((_user) => {
						logger.debug(`[AddCourse/checkUser] Found user: ${username.value}`);
						user.value = new User(_user);
						instructor_exists.value = true;
					})
					.catch((e) => {
						// expected: API returns UserNotFound
						logger.debug(`user '${username.value}' not found: ${JSON.stringify(e)}`);
						instructor_exists.value = false;
						// wipe out any existing user in case there was one?
						// Is there performance penalty for repeatedly calling new User()
						user.value = new User({ username: username.value });
					});
			},
			addCourse,
		};
	}
});
</script>

<template>
	<div>
		<q-card>
			<q-card-section>
				<div class="text-h6">New Course</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col">
						<q-input outlined v-model="course.course_name" label="Course Name" />
					</div>
				</div>
				<div class="row">
					<div class="col">
						<q-toggle v-model="course.visible" label="Visible" />
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
import { newCourse } from '../../store/common';

import { Course, ResponseError } from '../../store/models';
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
		const course_dates: Ref<DateRange> = ref({to:'',from:''});

		return {
			course,
			course_dates,
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
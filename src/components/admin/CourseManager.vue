<template>
	<div>
		<div class="q-pa-lg">
			<q-table
				title="All Courses"
				:rows="courses"
				:columns="columns"
				row-key="course_id"
				:filter="filter"
				selection="multiple"
				v-model:selected="selected"
				:visible-columns="['course_name', 'visible', 'starting_date', 'end_date']"
			>
				<template v-slot:body-cell-visible="props">
					<q-td :props="props">
						<div>
							<q-icon v-if="props.value" name="done"
								class="text-primary" style="font-size: 20px; font-weight: bold" />
						</div>
					</q-td>
				</template>

				<template v-slot:body-cell-course_name="props">
					<q-td :props="props">
						<router-link :to="`/courses/${props.row.course_id}/instructor`">{{ props.value }}</router-link>
					</q-td>
				</template>

				<template v-slot:top-right>
					<span style="margin-right: 20px">
						<q-btn color="primary" label="New Course" v-close-popup @click="new_course_dialog = true" />
					</span>
					<q-input dense debounce="300" v-model="filter" placeholder="Search">
						<template v-slot:append>
							<q-icon name="search" />
						</template>
					</q-input>
				</template>
			</q-table>
		</div>
		<q-dialog full-width v-model="new_course_dialog">
			<new-course-dialog @close-dialog="new_course_dialog = false" />
		</q-dialog>
	</div>
</template>

<script lang="ts">
import { defineComponent, computed, ref } from 'vue';
import { date } from 'quasar';
import { useCourseStore } from 'src/stores/courses';
import { Course } from 'src/common/models/courses';
import NewCourseDialog from './AddCourse.vue';

interface CourseDate {
	start: number;
	end: number;
}

export default defineComponent({
	name: 'AdminCourses',
	components: {
		NewCourseDialog
	},
	setup() {
		const courses = useCourseStore();
		const columns = [
			{
				name: 'course_id',
				label: 'Course ID',
				field: 'course_id'
			},
			{
				name: 'course_name',
				label: 'Course Name',
				field: 'course_name',
				sortable: true
			},
			{
				name: 'visible',
				label: 'Visible',
				field: 'visible',
				sortable: true
			},
			{
				name: 'starting_date',
				label: 'Starting Date',
				field: 'course_dates',
				format: (val: CourseDate) => date.formatDate(val.start * 1000, 'YYYY-MM-DD'),
				sortable: true
			},
			{
				name: 'end_date',
				label: 'Ending Date',
				field: 'course_dates',
				format: (val: CourseDate) => date.formatDate(val.end * 1000, 'YYYY-MM-DD'),
				sortable: true
			}
		];
		const filter = ref<string>('');
		const selected = ref<Array<Course>>([]);
		const new_course_dialog = ref<boolean>(false);

		return {
			columns,
			filter,
			selected,
			new_course_dialog,
			courses: computed(() => courses.courses)
		};
	}
});
</script>

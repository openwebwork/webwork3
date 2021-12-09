<template>
	<q-page class="q-pa-lg">
		<q-table
			:columns="columns"
			:rows="problem_sets"
			row-key="set_name"
			title="Problem Sets"
			:visible-columns="['set_visible', 'set_name', 'open_date', 'due_date', 'answer_date']"
			selection="single"
			:filter="filter"
			v-model:selected="selected"
		>
			<template v-slot:top-right>
				<span v-if="selected.length > 0" style="margin-right: 20px">
					<q-btn color="secondary" label="Edit Selected" />
				</span>
				<q-input borderless dense debounce="300" v-model="filter" placeholder="Search">
					<template v-slot:append>
						<q-icon name="search" />
					</template>
				</q-input>
			</template>
			<template v-slot:body-cell-set_name="props">
				<q-td :props="props">
					<q-badge color="green" v-if="props.row.set_type === 'HW'">H</q-badge>
					<q-badge color="purple" v-if="props.row.set_type === 'QUIZ'">Q</q-badge>
					<q-badge color="orange" v-if="props.row.set_type === 'REVIEW'">R</q-badge>
					<span style="margin-left: 10px">
						<router-link :to="link_info(props.row.set_id)">
						{{ props.row.set_name }}
						</router-link>
					</span>
				</q-td>
			</template>
			<template v-slot:body-cell-set_visible="props">
				<q-td :props="props">
					<div>
						<q-icon v-if="props.value" name="done"
							class="text-primary" style="font-size: 20px; font-weight: bold" />
					</div>
				</q-td>
			</template>
		</q-table>
	</q-page>
</template>

<script lang="ts">
import { defineComponent, computed, ref } from 'vue';
import { useStore } from 'src/store';
import { ProblemSet, QuizDates } from 'src/store/models/problem_sets';
import { formatDate } from 'src/common';

export default defineComponent({
	name: 'ProblemSetsManager',
	setup() {
		const store = useStore();
		const selected = ref<Array<ProblemSet>>([]);
		const filter = ref<string>('');
		const columns = [
			{ name: 'set_name', label: 'Set Name', field: 'set_name', sortable: true },
			{ name: 'set_id', label: 'set_id', field: 'set_id', sortable: true },
			{ name: 'set_visible', label: 'Visible', field: 'set_visible', sortable: true },
			{
				name: 'open_date', label: 'Open Date', field: 'set_dates',
				format: (val: QuizDates) => formatDate(`${val?.open ?? ''}`)
			},
			{
				name: 'due_date', label: 'Due Date', field: 'set_dates',
				format: (val: QuizDates) => formatDate(`${val?.due ?? ''}`)
			},
			{
				name: 'answer_date', label: 'Answer Date', field: 'set_dates',
				format: (val: QuizDates) => formatDate(`${val?.answer ?? ''}`)
			}
		];

		return {
			filter,
			selected,
			columns,
			problem_sets: computed(() => store.state.problem_sets.problem_sets),
			link_info: (_set_id: number) => ({
				name: 'ProblemSetDetails',
				params: {
					course_id: store.state.session.course.course_id,
					set_id: _set_id
				}
			})
		};
	}
});
</script>

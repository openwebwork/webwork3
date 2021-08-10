<template>
	<div class="q-pa-lg">
		<q-table
			:columns="columns"
			:rows="problem_sets"
			row-key="set_name"
			title="Problem Sets"
			:visible-columns="['set_visible','set_name','open_date','due_date','answer_date']"
			selection="single"
			:filter="filter"
			v-model:selected="selected"
		>
			<template v-slot:top-right>
				<span v-if="selected.length>0" style="margin-right: 20px">
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
					<q-badge color="green" v-if="props.row.set_type==='HW'">H</q-badge>
					<q-badge color="purple" v-if="props.row.set_type==='QUIZ'">Q</q-badge>
					<q-badge color="orange" v-if="props.row.set_type==='REVIEW'">R</q-badge>
					 {{ props.row.set_name}}
				</q-td>
			</template>
			<template v-slot:body-cell-set_visible="props">
				<q-td :props="props">
					<div>
						<q-icon
							v-if="props.value"
							name="done"
							class="text-primary"
							style="font-size: 20px; font-weight: bold"
						/>
					</div>
				</q-td>
			</template>
		</q-table>
	</div>
</template>

<script lang="ts">
import { Dictionary } from 'src/store/models';
import { date } from 'quasar';
import { defineComponent, computed, ref, Ref } from 'vue';
import { useStore } from '../../store';
import { ProblemSet } from '../../store/models';

export default defineComponent({
	name: 'ProblemSetsManager',
	setup() {
		const store = useStore();
		const selected: Ref<Array<ProblemSet>> = ref([]);
		const filter: Ref<string> = ref('');
		const columns = [
			{
				name: 'set_name',
				label: 'Set Name',
				field: 'set_name',
				sortable: true
			},
			{
				name: 'set_id',
				label: 'set_id',
				field: 'set_id',
				sortable: true
			},
			{
				name: 'set_visible',
				label: 'Visible',
				field: 'set_visible',
				sortable: true
			},
			{
				name: 'open_date',
				label: 'Open Date',
				field: 'dates',
				format: (val: Dictionary<string>) => formatDate(val.open)
			},
			{
				name: 'due_date',
				label: 'Due Date',
				field: 'dates',
				format: (val: Dictionary<string>) => formatDate(val.due)
			},
			{
				name: 'answer_date',
				label: 'Answer Date',
				field: 'dates',
				format: (val: Dictionary<string>) => formatDate(val.answer)
			}
		];
		function formatDate(_date_to_format: string) {
			const _date = new Date();
			_date.setTime(parseInt(_date_to_format)*1000); //js dates have milliseconds instead of standard unix epoch
			return date.formatDate(_date, 'MM-DD-YYYY [at] h:mmA'); // have the format changeable?
		}
		return {
			filter,
			selected,
			columns,
			problem_sets: computed(() => store.state.problem_sets.problem_sets)
		};
	}
});
</script>

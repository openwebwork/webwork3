<template>
	<div class="q-pa-lg">
		<q-table
			:columns="columns"
			:rows="problem_sets"
			row-key="set_id"
			title="Problem Sets"
			:visible-columns="['set_visible','set_name','set_type','open_date']"
			selection="multiple"
		>
			<template v-slot:top>
				Top
			</template>
			<template v-slot:body-cell-set_visible="props">
				<q-td :props="props">
					<div>
						<q-icon v-if="props.value" name="done"  class="text-primary"  style="font-size: 20px; font-weight: bold" />
					</div>
				</q-td>
			</template>
		</q-table>
	</div>
</template>

<script lang="ts">
import { Dictionary } from '@/store/models';
import { date } from 'quasar';
import { defineComponent, computed } from 'vue';
import { useStore } from '../../store';
export default defineComponent({
	name: 'ProblemSetsManager',
	setup() {
		const store = useStore();
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
				sortable: true,
			},
			{
				name: 'set_type',
				label: 'Set Type',
				field: 'set_type',
				sortable: true
			},
			{
				name: 'open_date',
				label: 'Open Date',
				field: 'dates', //(dates: Dictionary<string>) => dates.open,
				format: (val: Dictionary<string>) => {
					const open_date = new Date();
					open_date.setTime(10000000000*Math.random()+parseInt(val.open));
					console.log(open_date);
					return date.formatDate(open_date,'MM-DD-YYYY') //row.dates.open
				}
			}
		];
		return {
			columns,
			problem_sets: computed( () => store.state.problem_sets.problem_sets)
		}

	}
});
</script>
<template>
	<div class="row">
		<div v-for="day in week" :key="day" class="col day" :class="background(day)">
			<span class="date">{{ shortDay(day) }}</span>
		</div>
		<!--
		<draggable
			v-model="assignment_info[index]"
			group="calendar"
			class="assignments"
			@start="drag = true"
			@end="drag = false"
			@change="assignChange(day, $event)"
		>
			<div
				v-for="assignment in assignment_info[index]"
				:key="assignment.id"
				:class="show(assignment)"
				class="assign border rounded border-dark pl-1 p-0"
				:style="getProblemSet(assignment.set_id).visible ? '' : 'font-style: italic'"
			>
				{{ assignment.set_id.replace(/_/g, " ") }}
				<b-icon-question-circle-fill
					:id="assignment.id"
					class="float-right"
					font-scale="1.5"
				/>
				<b-popover :target="assignment.id" triggers="hover focus">
					<template #title>
						<router-link :to="'set-view/' + assignment.set_id">
							{{ assignment.set_id.replace(/_/g, " ") }}
						</router-link>
					</template>
				<table>
					<tbody>
						<tr>
							<td colspan="2">
								{{ assignment.type }} date ends at
								{{ assignment.date.format("hh:mma") }}
							</td>
						</tr>
						<tr>
							<td>Visible:</td>
							<td>{{ getProblemSet(assignment.set_id).visible }}</td>
						</tr>
						<tr>
							<td>Num. Probs.:</td>
							<td>{{ getProblemSet(assignment.set_id).problems.length }}</td>
						</tr>
						<tr>
							<td>Assigned Users:</td>
							<td>
								{{ getProblemSet(assignment.set_id).assigned_users.length }}/{{ num_users }}
							</td>
						</tr>
					</tbody>
				</table>
			</b-popover>
		</draggable>
		--></div>
</template>

<script lang="ts">
import { computed, defineComponent } from 'vue';
import { date } from 'quasar';

export default defineComponent({
	name: 'CalendarRow',
	props: {
		first_day_of_week: Date,
		course_id: String
	},

	setup(props) {
		const first_day_of_week = props.first_day_of_week || Date.now();

		return {
			week: computed(
				(): Array<Date> => [0, 1, 2, 3, 4, 5, 6].map((num) => date.addToDate(first_day_of_week, { days: num }))
			),
			shortDay: (day: Date) => (day.getDate() === 1 ? date.formatDate(day, 'MMM D') : date.formatDate(day, 'D')),
			background: (day: Date) =>
				day.getDate() === 1 ? 'firstday' : date.isSameDate(day, new Date(), 'day') ? 'today' : ''
		};
	}
	// private drag = false;
	// private get num_users() {
	//   return users_store.users.length;
	// }
	// private getProblemSet(set_id: string): ProblemSet | undefined {
	//   return problem_set_store.problem_sets.find(
	//     (_set: ProblemSet) => _set.set_id === set_id
	//   );
	// }
	// private assignChange(
	//   new_date: dayjs.Dayjs,
	//   evt: ChangeEvent<AssignmentInfo>
	// ) {
	//   if (Object.prototype.hasOwnProperty.call(evt, "removed")) {
	//     // if the change event is fired but it is removed.
	//     return;
	//   } else if (Object.prototype.hasOwnProperty.call(evt, "added")) {
	//     const date_dropped_onto = dayjs(new_date); // make a copy of the date object
	//     const attrs: { [key: string]: number } = {};
	//     // make a copy of the set
	//     const set = Object.assign(
	//       {},
	//       this.getProblemSet(evt.added.element.set_id)
	//     );
	//     // adjust the time to be the same as the previous assignment time.
	//     if (evt.added.element.date) {
	//       // it was dragged/changed from another calendar
	//       date_dropped_onto.hour(evt.added.element.date.hour());
	//       date_dropped_onto.minute(evt.added.element.date.minute());
	//       attrs[evt.added.element.type + "_date"] = date_dropped_onto.unix();
	//     } else if (evt.added.element.due_date) {
	//       // it was dragged from the sidebar
	//       attrs.due_date = date_dropped_onto.unix();
	//       attrs.reduced_scoring_date = dayjs(date_dropped_onto).unix();
	//       attrs.open_date = dayjs(date_dropped_onto).subtract(7, "day").unix();
	//       attrs.answer_date = dayjs(date_dropped_onto).add(7, "day").unix();
	//     }
	//     if (set) {
	//       Object.assign(set, attrs);
	//       problem_set_store.updateProblemSet(set);
	//     }
	//   }
});
</script>

<style type="text/css" scoped>
.day {
	max-width: 10%;
	height: 100px;
	border: black solid 1px;
	background: lightyellow;
	vertical-align: top;
}

.date {
	font-weight: bold;
}

.firstday {
	background: lightpink;
}

.today {
	background: lightgreen;
}
</style>

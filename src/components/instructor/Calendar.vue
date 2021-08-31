<template>
	<div class="q-pa-md">
		<div class="row">
			<div class="col-3">
				<span style="font-weight: bold; font-size: 140%"> {{ current_month }}</span>
			</div>
			<div class="col-5">
				<q-btn-group push>
					<q-btn push :label="$t('calendar.prev_week')" @click="prev" />
					<q-btn push :label="$t('calendar.today')" @click="today"/>
					<q-btn push :label="$t('calendar.next_week')" @click="next" />
				</q-btn-group>
			</div>
		</div>
		<template v-for="day in calendar_days" :key="day">
			<calendar-row :first_day_of_week="day" />
		</template>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, computed } from 'vue';
import { date } from 'quasar';
import CalendarRow from 'components/common/CalendarComponents/CalendarRow.vue';

export default defineComponent({
	name: 'Calendar',
	components: {
		CalendarRow
	},
	props: {
		course_id: String
	},
	setup() {

		/* this is a bit of a mess
		 Not sure why I'm getting serious typescript errors
		 related to refs and dates here. */

		const first_day_of_month: Date = new Date();
		first_day_of_month.setDate(1);
		// first day of the calendar
		let d: Date = new Date();
		const first_day= ref(d);
		// = ref(date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() }));
		return {
			first_day,
			the_day: computed(() => first_day.value),
			calendar_days: computed(() => [0, 1, 2, 3, 4]
				.map((num) => date.addToDate(d, { days: 7 * num }))),
			current_month: computed(() => date.formatDate(d, 'MMMM, YYYY')),
			prev: () => (d = date.subtractFromDate(d, { days: 7 })),
			next: () => (d = date.addToDate(d, { days: 7 })),
			today: () => (d
				= date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() }))
		};
	}
});
</script>

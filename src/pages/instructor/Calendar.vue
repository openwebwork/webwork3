<template>
	<q-page class="q-pa-md">
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
	</q-page>
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

		/* Needed to "convert" all first_day.values to Date objects
			but unclear why.  removing as Date results in typescript errors.
			Perhaps this is a bug in some package.  Try removing with an upgrade.
		*/

		const first_day_of_month: Date = new Date();
		first_day_of_month.setDate(1);
		// first day of the calendar
		const first_day // = ref(d);
			= ref(date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() }));

		return {
			first_day,
			the_day: computed(() => first_day.value),
			calendar_days: computed(() =>
				[0, 1, 2, 3, 4].map((num) => date.addToDate(first_day.value as Date, { days: 7 * num }))
			),
			current_month: computed(() => date.formatDate(first_day.value as Date, 'MMMM, YYYY')),
			prev: () => {
				first_day.value = date.subtractFromDate(first_day.value as Date, { days: 7 });
			},
			next: () => {
				first_day.value = date.addToDate(first_day.value as Date, { days: 7 });
			},
			today: () => {
				first_day.value = date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() });
			}
		};
	}
});
</script>

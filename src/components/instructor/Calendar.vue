<template>
	<div class="q-pa-md">
		<div class="row">
			<div class="col-3">
				<span style="font-weight: bold; font-size: 140%"> {{ current_month }}</span>
			</div>
			<div class="col-5">
				<q-btn-group push>
					<q-btn push label="Previous Week" @click="prev" />
					<q-btn push label="Today" @click="today"/>
					<q-btn push label="Next Week" @click="next" />
				</q-btn-group>
			</div>
		</div>
		<template v-for="day in calendar_days" :key="day">
			<calendar-row :first_day_of_week="day"/>
		</template>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, computed } from 'vue';
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
		const first_day_of_month: Date = new Date();
		first_day_of_month.setDate(1);
		// first day of the calendar
		// console.log(date.subtractFromDate(today, { days: today.getDay() }));
		//const first_day: Ref<Date> = ref(date.subtractFromDate(today, { days: today.getDay() }));
		const first_day: Ref<Date>
			= ref(date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() }));
		return {
			first_day,
			calendar_days: computed(
				() => [0, 1, 2, 3, 4].map((num) => date.addToDate(first_day.value, { days: 7 * num }))),
			current_month: computed(() => date.formatDate(first_day.value, 'MMMM, YYYY')),
			prev: () => first_day.value = date.subtractFromDate(first_day.value, { days: 7 }),
			next: () => first_day.value = date.addToDate(first_day.value, { days: 7 }),
			today: () => first_day.value
				= date.subtractFromDate(first_day_of_month, { days: first_day_of_month.getDay() })
		};
	}
});
</script>

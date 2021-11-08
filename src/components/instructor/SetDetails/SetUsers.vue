<template>
	<q-table
		title="Assign Users and Override Set Parameters"
		:rows="merged_user_sets"
		:columns="columns"
		:filter="filter"
		v-model:selected="to_unassign"
		selection="multiple"
		row-key="user_id"
	>
		<template v-slot:body-cell-edit_dates="props">
			<q-td :props="props">
				<q-btn
					v-if="props.row.set_dates"
					color="primary" label="Edit Dates" size="sm"
					@click="openOverrides(props.row.course_user_id)"
					/>
			</q-td>
		</template>

		<template v-slot:top-right>
			<span style="padding-right:1em">
				<q-btn v-if="to_unassign.length>0"
					size="sm" color="primary" label="Unassign Selected Users"
					@click="unassignFromSet" />
				<q-btn v-else
					size="sm" color="primary" label="Assign to all Users"
					@click="assignToAllUsers" />
			</span>
			<q-input outlined dense debounce="300" v-model="filter" placeholder="Search">
				<template v-slot:append>
					<q-icon name="search" />
				</template>
			</q-input>
		</template>
	</q-table>

	<!-- Dialog that popups for editing dates -->
	<q-dialog v-model="edit_dialog">
			<q-card>
				<q-card-section>
					<div class="text-h6">Problem Set Overrides</div>
				</q-card-section>

				<q-card-section class="q-pt-none">
					<homework-dates
						:dates="date_edit"
						:reduced_scoring="true"
					/>
				</q-card-section>

				<q-card-actions align="right">
					<q-btn flat label="Cancel" color="accent" v-close-popup />
					<q-btn flat label="Save Problem Set Overrides" color="primary"
						@click="saveOverrides" />
				</q-card-actions>
			</q-card>
		</q-dialog>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';
import type { Ref } from 'vue';
import { useQuasar } from 'quasar';
import { useStore } from '@/store';
import { useRoute } from 'vue-router';
import { assign, clone, pick } from 'lodash-es';

import { logger } from '@/boot/logger';
import { HomeworkSetDates, MergedUserSet, ProblemSet, UserSet } from '@/store/models/problem_sets';
import { parseNonNegInt, Dictionary } from '@/store/models';
import { formatDate } from '@/common';
import HomeworkDates from './HomeworkDates.vue';
import type { ResponseError } from '@/store/models';

interface Column {
	name: string;
	label: string;
	field?: string | ((row: MergedUserSet) => number);
	format?: (val: number) => string;
}

export default defineComponent({
	name: 'SetUsers',
	components: {
		HomeworkDates
	},
	setup() {
		const $q = useQuasar();
		const store = useStore();
		const route = useRoute();

		const problem_set: Ref<ProblemSet> = ref(new ProblemSet());

		// This is needed for editing dates of a single user
		const merged_user_set: Ref<MergedUserSet> = ref(new MergedUserSet());
		const columns: Array<Column> = [
			{ name: 'first_name', label: 'First Name', field: 'first_name' },
			{ name: 'last_name', label: 'Last Name', field: 'last_name' },
			{ name: 'edit_dates', label: 'Edit Dates' }
		];
		const edit_dialog: Ref<boolean> = ref(false);
		const date_edit: Ref<Dictionary<number>> = ref({});
		const to_unassign: Ref<Array<MergedUserSet>> = ref([]);

		const updateProblemSet = () => {
			if (route.params.set_id) {
				problem_set.value = store.state.problem_sets.problem_sets.find(
					_set => _set.set_id === parseNonNegInt(route.params.set_id as string)
				) ?? new ProblemSet();
			}
			if (problem_set.value.set_id && problem_set.value.set_id > 0) {
				if (problem_set.value.set_type === 'HW') {
					columns.splice(columns.length, 0,
						{ name: 'open_date', label: 'Open Date', format: formatTheDate,
							field: row => row.set_dates ? (row.set_dates as HomeworkSetDates).open : 0 },
						{ name: 'due_date', label: 'Due Date', format: formatTheDate,
							field: row => row.set_dates ? (row.set_dates as HomeworkSetDates).due : 0 },
						{ name: 'answer_date', label: 'Answer Date', format: formatTheDate,
							field: row => row.set_dates ? (row.set_dates as HomeworkSetDates).answer :  0 }
					);
					date_edit.value = clone(problem_set.value.set_dates);
				}
			}
		};

		const updateMergedUserSet = (course_user_id: number) => {
			merged_user_set.value = store.state.problem_sets.merged_user_sets
				.find(_user_set => _user_set.course_user_id === course_user_id) ??
				new MergedUserSet();
		};

		const formatTheDate = (val: number): string => val === 0 ? '' : formatDate(val);

		updateProblemSet();
		watch([store.state.problem_sets.merged_user_sets], updateProblemSet);

		return {
			columns,
			users: computed(() => store.state.users.merged_users),
			// produces the merge between users and user_sets for display
			merged_user_sets: computed(() =>
				store.state.users.merged_users.map(_user => {
					const user_set = store.state.problem_sets.merged_user_sets
						.find(_user_set => _user_set.course_user_id === _user.course_user_id);
					return user_set && user_set.toObject ?
						assign({}, _user.toObject(), user_set?.toObject()) :
						_user.toObject();
				})
			),
			edit_dialog,
			date_edit,
			filter: ref(''),
			to_unassign,
			formatDate,
			saveOverrides: async () => {
				logger.debug('closing the overrides dialog');
				const updated_user_set = new UserSet(pick(merged_user_set.value, UserSet.ALL_FIELDS));
				updated_user_set.set_dates = date_edit.value;
				if (updated_user_set.isValid()) {
					try {
						await store.dispatch('problem_sets/updateUserSet', updated_user_set);
						$q.notify({
							message: `The problem set '${merged_user_set.value.set_name ?? ''}' ` +
								`for user ${merged_user_set.value.username ?? ''} has been succesfully updated.`,
							color: 'green'
						});
					} catch (err) {
						const error = err as ResponseError;
						$q.notify({ message: error.message, color: 'red' });
					}
				}
				edit_dialog.value = false;
			},
			openOverrides: (course_user_id: number) => {
				updateMergedUserSet(course_user_id);
				date_edit.value = clone(merged_user_set.value.set_dates);
				edit_dialog.value = true;
			},
			assignToAllUsers: async () => {
				// find users not assigned.
				const users_to_assign = store.state.users.merged_users.filter(_merged_user => {
					return store.state.problem_sets.merged_user_sets
						.findIndex(_user_set => _user_set.course_user_id === _merged_user.course_user_id) < 0;
				});
				for(const _user of users_to_assign) {
					const _user_set = new UserSet({
						set_id: problem_set.value.set_id,
						course_user_id: _user.course_user_id,
						set_version: problem_set.value.set_version
					});
					try {
						await store.dispatch('problem_sets/addUserSet', _user_set);
						$q.notify({
							message: `The user ${_user.username ?? ''} has been assigned to `
								+ `${problem_set.value.set_name ?? ''}`,
							color: 'green'
						});
					} catch (err) {
						const error = err as ResponseError;
						$q.notify({ message: error.message, color: 'red' });
					}

				}
			},
			unassignFromSet: async () => {
				const usernames = to_unassign.value.map(_user => _user.username);
				const conf = confirm(`Do you want to unassign the following users: ${usernames.join(', ')}`
					+ '? There is no undo for this.');
				if (conf) {
					for(const user of to_unassign.value) {
						try {
							await store.dispatch('problem_sets/deleteUserSet',
								new UserSet(pick(user, UserSet.ALL_FIELDS)));
							$q.notify({
								message: `The user ${user.username ?? ''} has been unassigned from `
									+ `${problem_set.value.set_name ?? ''}`,
								color: 'green'
							});
						} catch (err) {
							const error = err as ResponseError;
							$q.notify({ message: error.message, color: 'red' });
						}
					}
				}
			}
		};
	},
	async created() {
		// fetch the user sets for this set
		const store = useStore();
		const route = useRoute();
		if(route.params.set_id) {
			logger.debug('Loading UserSets');
			await store.dispatch('problem_sets/fetchMergedUserSets', {
				course_id: route.params.course_id,
				set_id: route.params.set_id
			});
		}
	}
});
</script>

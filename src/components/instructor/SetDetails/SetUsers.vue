<template>
	<q-table
		title="Assign Users and Override Set Parameters"
		:rows="user_set_info"
		:columns="columns"
		:filter="filter"
		row-key="user_id"
	>
		<template v-slot:body-cell-assign="props">
			<q-td :props="props">
				<q-icon v-if="props.row.assigned"
					name="check_box" size="sm" color="primary"
					@click="changeAssigned(props.row.course_user_id, false)"
				/>
				<q-icon v-else
					name="check_box_outline_blank" size="sm"
					@click="changeAssigned(props.row.course_user_id, true)"
				/>
			</q-td>
		</template>

		<template v-slot:body-cell-edit_dates="props">
			<q-td :props="props">
				<q-btn round color="primary"
					v-if="props.row.assigned"
					icon="edit" size="xs"
					@click="openOverrides(props.row.course_user_id)"
				/>
			</q-td>
		</template>

		<template v-slot:top-right>
			<span style="padding-right:1em">
				<q-btn
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
					<homework-dates-view
						v-if="problem_set.set_type === 'HW'"
						:dates="(date_edit as HomeworkSetDates)"
						:reduced_scoring="reduced_scoring"
						@update-dates="(val: HomeworkSetDates) => date_edit = val"
					/>
					<quiz-dates-view
						v-if="problem_set.set_type ==='QUIZ'"
						:dates="(date_edit as QuizDates)"
						@update-dates="(val: QuizDates) => date_edit = val"
					/>
					<review-set-dates-view
						v-if="problem_set.set_type ==='REVIEW'"
						:dates="(date_edit as ReviewSetDates)"
						@update-dates="(val: ReviewSetDates) => date_edit = val"
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
import { useQuasar } from 'quasar';
import { useRoute } from 'vue-router';
import { useUserStore } from 'src/stores/users';
import { useProblemSetStore } from 'src/stores/problem_sets';

import { logger } from 'boot/logger';
import { MergedUserSet, UserSet, MergedUserHomeworkSet, MergedUserQuiz,
	MergedUserReviewSet, parseUserSet } from 'src/common/models/user_sets';
import { ProblemSet, HomeworkSet, HomeworkSetDates, QuizDates,
	ReviewSetDates, ProblemSetDates } from 'src/common/models/problem_sets';
import { parseNonNegInt } from 'src/common/models/parsers';
import { formatDate } from 'src/common/views';
import HomeworkDatesView from './HomeworkDates.vue';
import ReviewSetDatesView from './ReviewSetDates.vue';
import QuizDatesView from './QuizDates.vue';
import type { ResponseError } from 'src/common/api-requests/interfaces';

type FieldType =
	((row: MergedUserHomeworkSet) => number) |
	((row: MergedUserQuiz) => number) |
	((row: MergedUserReviewSet) => number);

interface UserInfo {
	course_user_id: number;
	first_name: string;
	last_name: string;
	assigned: boolean;
	set_dates: HomeworkSetDates | QuizDates | ReviewSetDates;
}

interface Column {
	name: string;
	label: string;
	align?: string;
	field?: string | FieldType;
	format?: string | ((num: number) => string) | FieldType;
}

export default defineComponent({
	name: 'SetUsers',
	components: {
		HomeworkDatesView,
		ReviewSetDatesView,
		QuizDatesView
	},
	setup() {
		const $q = useQuasar();
		const users  = useUserStore();
		const problem_sets = useProblemSetStore();
		const route = useRoute();

		const problem_set = ref<ProblemSet>(new ProblemSet());

		// This is needed for editing dates of a single user
		const merged_user_set = ref<MergedUserSet>(new MergedUserSet());
		const columns: Array<Column> = [
			{ name: 'assign', label: 'Assign', align: 'center' },
			{ name: 'first_name', label: 'First Name', field: 'first_name' },
			{ name: 'last_name', label: 'Last Name', field: 'last_name' },
			{ name: 'edit_dates', label: 'Edit Dates', align: 'center' }
		];
		const edit_dialog = ref<boolean>(false);
		const date_edit = ref<ProblemSetDates | null>(null);
		const user_set_info = ref<Array<UserInfo>>([]);

		const formatTheDate = (val: number): string => val === 0 ? '' : formatDate(val);

		// An array of User info for the table including if the set is assigned and any
		// overridden dates.
		const updateUserSetInfo = () => {
			const merged_user_sets = problem_sets.merged_user_sets;
			user_set_info.value = users.merged_users.map(user => {
				// This matches the user_set for the given user.
				const user_set = merged_user_sets.find(s => s?.course_user_id === user.course_user_id);
				return {
					course_user_id: user.course_user_id,
					first_name: user.first_name ?? '',
					last_name: user.last_name ?? '',
					assigned: user_set != undefined,
					set_dates: user_set == undefined ? (new HomeworkSetDates() as ProblemSetDates) : user_set?.set_dates
				};
			});
		};

		/**
		 * Assign the user with given course_user_id to the problem in problem_set.
		 * This also makes an api-request.
		 */

		const assignUser = async (course_user_id: number) => {
			const user = users.merged_users.find(u => u.course_user_id === course_user_id);
			logger.debug(`assigning the set '${problem_set.value.set_name}' to the user '${user?.username ?? ''}'`);
			const set_params = {
				set_id: problem_set.value.set_id,
				course_user_id,
				// TODO: handle set versioning.
				set_version: 1,
				set_type: problem_set.value.set_type
			};
			const user_set = parseUserSet(set_params);
			try {
				await problem_sets.addUserSet(user_set);
				$q.notify({
					message: `The user ${user?.username ?? ''} has been assigned to `
						+ `${problem_set.value.set_name ?? ''}`,
					color: 'green'
				});
				logger.debug(`The user ${user?.username ?? ''} has been assigned to `
						+ `${problem_set.value.set_name ?? ''}`);
			} catch (err) {
				const error = err as ResponseError;
				$q.notify({ message: error.message, color: 'red' });
			}

		};

		const unassignUser = async (course_user_id: number) => {
			const user = users.merged_users.find(u => u.course_user_id === course_user_id);
			const merged_user_set = problem_sets.merged_user_sets.find(u => u.course_user_id === course_user_id);
			if (merged_user_set) {
				const user_set = new UserSet(merged_user_set.toObject(UserSet.ALL_FIELDS));
				try {
					await problem_sets.deleteUserSet(user_set);
					const msg =  `The user ${user?.username ?? ''} has been unassigned from the set `
						+ `${problem_set.value.set_name ?? ''}`;
					$q.notify({ message: msg, color: 'green' });
					logger.debug(msg);
				} catch (err) {
					const error = err as ResponseError;
					$q.notify({ message: error.message, color: 'red' });
					logger.error(error.message);
				}
			} else {
				logger.error(`The user_set for set '${problem_set.value.set_name}' ` +
					`for user '${user?.username ?? ''}' is not found.`);
			}
		};

		const changeAssigned = async (course_user_id: number, assigned: boolean) => {
			const i = user_set_info.value.findIndex(u => u.course_user_id === course_user_id);
			if (i >= 0) {
				const user_set = user_set_info.value[i];
				user_set.assigned = assigned;
				if (assigned) {
					user_set.set_dates.set(problem_set.value.set_dates.toObject());
				}
				// use splice so the table reacts.
				user_set_info.value.splice(i, 1, user_set);
			}
			if (assigned) {
				await assignUser(course_user_id);
			} else {
				$q.dialog({
					message: 'Unassigning a user from a set cannot be undone.  Do you want to proceed?',
					cancel: true,
					persistent: true
				}).onOk(() => {
					void unassignUser(course_user_id);
				}).onCancel(() => {
					// return the user to the selected rows of the table.
					updateUserSetInfo();
				});
			}
		};

		const saveOverrides = async () => {
			logger.debug('closing the overrides dialog');
			const set_params = merged_user_set.value.toObject(UserSet.ALL_FIELDS);
			const updated_user_set = parseUserSet(set_params);
			updated_user_set.set_dates.set(date_edit.value?.toObject() ?? {});
			if (updated_user_set.hasValidDates()) {
				try {
					await problem_sets.updateUserSet(updated_user_set);
					const msg = `The problem set '${merged_user_set.value.set_name ?? ''}' ` +
							`for user ${merged_user_set.value.username ?? ''} has been succesfully updated.`;
					$q.notify({
						message: msg,
						color: 'green'
					});
					logger.debug(msg);
					updateUserSetInfo();
				} catch (err) {
					const error = err as ResponseError;
					$q.notify({ message: error.message, color: 'red' });
				}
			}
			edit_dialog.value = false;
		};

		const assignToAllUsers = async () => {
			// find users not assigned.
			const users_to_assign = users.merged_users.filter(merged_user =>
				problem_sets.merged_user_sets
					.findIndex(user_set => user_set.course_user_id === merged_user.course_user_id) < 0
			);
			for (const user of users_to_assign) {
				await assignUser(user.course_user_id);
			}
			updateUserSetInfo();
		};

		updateUserSetInfo();
		watch(() => problem_sets.merged_user_sets, updateUserSetInfo);

		const updateProblemSet = () => {
			if (route.params.set_id) {
				problem_set.value = problem_sets.problem_sets.find(
					_set => _set.set_id === parseNonNegInt(route.params.set_id as string)
				) ?? new ProblemSet();
			}
			if (problem_set.value.set_id && problem_set.value.set_id > 0) {
				if (problem_set.value.set_type === 'HW') {
					columns.splice(columns.length, 0, {
						name: 'open_date',
						label: 'Open Date',
						format: formatTheDate,
						field: (row: MergedUserHomeworkSet) => row.set_dates.open ?? 0
					},
					{
						name: 'due_date',
						label: 'Due Date',
						format: formatTheDate,
						field: (row: MergedUserHomeworkSet) => row.set_dates.due ?? 0
					},
					{
						name: 'answer_date',
						label: 'Answer Date',
						format: formatTheDate,
						field: (row: MergedUserHomeworkSet) => row.set_dates.answer ?? 0
					});
				}
				if ((problem_set.value as unknown as MergedUserHomeworkSet).set_params.enable_reduced_scoring) {
					columns.splice(columns.length - 1, 0,
						{
							name: 'reduced_scoring_date',
							label: 'Reduced Scoring Date',
							format: formatTheDate,
							field: (row: MergedUserHomeworkSet) => row.set_dates ?
								row.set_dates.reduced_scoring ?? 0 :
								0
						}
					);
				} else if (problem_set.value.set_type === 'QUIZ') {
					columns.splice(columns.length, 0,
						{
							name: 'open_date',
							label: 'Open Date',
							format: formatTheDate,
							field: (row: MergedUserQuiz) => row.set_dates ? (row.set_dates.open ?? 0) : 0
						},
						{
							name: 'due_date',
							label: 'Due Date',
							format: formatTheDate,
							field: (row: MergedUserQuiz) => row.set_dates ? (row.set_dates.due ?? 0) : 0
						},
						{
							name: 'answer_date',
							label: 'Answer Date',
							format: formatTheDate,
							field: (row: MergedUserQuiz) => row.set_dates ? (row.set_dates.answer ?? 0) :  0
						}
					);
				} else if (problem_set.value.set_type === 'REVIEW') {
					columns.splice(columns.length, 0,
						{
							name: 'open_date',
							label: 'Open Date',
							format: formatTheDate,
							field: (row: MergedUserReviewSet) => row.set_dates ? (row.set_dates.open ?? 0) : 0
						},
						{
							name: 'closed_date',
							label: 'Closed Date',
							format: formatTheDate,
							field: (row: MergedUserReviewSet) => row.set_dates ? (row.set_dates.closed ?? 0) : 0
						},
					);
				}
				date_edit.value = problem_set.value.set_dates.clone();
			}
		};

		const updateMergedUserSet = (course_user_id: number) => {
			merged_user_set.value = problem_sets.merged_user_sets
				.find(set => set.course_user_id === course_user_id) ?? new MergedUserSet();
		};

		updateProblemSet();
		watch(() => problem_sets.merged_user_sets, updateProblemSet);

		return {
			HomeworkSetDates,
			QuizDates,
			ReviewSetDates,
			columns,
			users: computed(() => users.merged_users),
			// produces the merge between users and user_sets for display
			problem_set,
			user_set_info,
			edit_dialog,
			date_edit,
			filter: ref(''),
			formatDate,
			saveOverrides,
			openOverrides: (course_user_id: number) => {
				updateMergedUserSet(course_user_id);
				date_edit.value = merged_user_set.value.set_dates;
				edit_dialog.value = true;
			},
			assignToAllUsers,
			changeAssigned,
			reduced_scoring: computed(() => {
				if (problem_set.value.set_type === 'HW') {
					const hw_set = problem_set.value as HomeworkSet;
					return hw_set.set_params.enable_reduced_scoring;
				} else {
					return false;
				}
			})
		};
	}
});
</script>

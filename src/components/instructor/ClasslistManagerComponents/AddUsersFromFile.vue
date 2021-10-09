<template>
	<div>
		<q-card>
			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col-3">
						<div class="text-h6">Adding Users From a File</div>
					</div>
					<div class="col-3">
						<q-file v-model="file" label="Select a classlist file (as CSV)" />
					</div>
					<div class="col-3">
						<q-btn @click="loadFile" :disable="file.name===''">Load File</q-btn>
					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row" v-if="merged_users.length !== 0">
					<div class="col-3">
						<q-toggle v-model="first_row_header" />
						First row is Header
					</div>
					<div class="col-3">
						<q-toggle v-model="use_single_role"/> Import All users as
					</div>
					<div class="col-3">
							<q-select :options="roles" v-model="common_role" />
					</div>
				</div>
				<div class="row">
					<div class="col-5 q-pa q-ma-lg" v-show="selected_user_error">
						<q-banner dense inline-actions class="text-white bg-red rounded-borders">
							There are validation errors with the loaded data. Any data row with an
							error will not be added.
						</q-banner>
					</div>
					<div class="col-5 q-pa q-ma-lg" v-show="users_already_in_course">
						<q-banner dense inline-actions class="bg-yellow-3 rounded-borders">
							The highlighted users below are already present in the course and will not
							be added.
						</q-banner>
					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col-12 q-pa-md" v-if="merged_users.length > 0">
						<q-table class="loaded-users-table"
							:rows="merged_users" row-key="_row" :columns="columns"
							v-model:selected="selected" selection="multiple"
							:pagination="{ rowsPerPage: 0 }"
							:loading="loading"
						>

							<template v-slot:header-cell="props">
								<q-th :props="props">
									<q-select :options="user_fields.map( (f) => f.label)"
										v-model="column_headers[props.col.name]"/>
								</q-th>
							</template>

							<template v-slot:body-cell="props">
								<q-td :class="getErrorClass(props.col.name, props.row._error)">
										<span  v-if="hasError(props)">
											{{ props.value }}
											<q-badge
												color="black"
												v-if="props.row._error.type === 'error' "
											>?
												<q-tooltip>
													{{ props.row._error.message }}
												</q-tooltip>
											</q-badge>
										</span>
										<span v-else>
											{{ props.value }}
										</span>
								</q-td>
							</template>

						</q-table>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Cancel" v-close-popup />
				<q-btn flat :label="`Add ${merged_users_to_add.length} Users and Close`" @click="addUsers" />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import type { Ref } from 'vue';
import { defineComponent, ref, computed, watch } from 'vue';
import { useQuasar } from 'quasar';
import { parse } from 'papaparse';
import { AxiosError } from 'axios';
import { logger } from 'boot/logger';

import { useStore } from 'src/store';
import type { Dictionary, MergedUser, User, ResponseError } from 'src/store/models';
import { newUser, parseMergedUser, newCourseUser, newMergedUser } from 'src/store/utils/users';
import { pick, fromPairs, values, invert, mapValues, clone, isUndefined, assign, filter } from 'lodash-es';

interface ParseError {
	type: string;
	col?: string;
	message: string;
	field?: string;
	entire_row?: boolean;
}

type UserFromFile = {
	_row?: number;
	_error?: ParseError
} & {
	[prop: string]: string
};

export default defineComponent({
	name: 'AddUsersFromFile',
	emits: ['closeDialog'],
	setup(props, context) {
		const store = useStore();
		const $q = useQuasar();
		const file: Ref<File> = ref(new File([], ''));
		// stores all users from the file as well as parsing errors
		const merged_users: Ref<Array<UserFromFile>> = ref([]);
		const selected: Ref<Array<UserFromFile>> = ref([]); // stores the selected users
		const column_headers: Ref<Dictionary<string>> = ref({});
		const user_param_map: Ref<Dictionary<string>> = ref({}); // provides a map from column number to field name
		const use_single_role: Ref<boolean> = ref(false);
		const common_role: Ref<string|null> = ref(null);
		const loading: Ref<boolean> = ref(false); // used to indicate parsing is occurring

		const first_row_header: Ref<boolean> = ref(false);
		const header_row: Ref<UserFromFile> = ref({});
		const merged_users_to_add: Ref<Array<MergedUser>> = ref([]);
		const selected_user_error: Ref<boolean> = ref(false);
		const users_already_in_course: Ref<boolean> = ref(false);

		const user_fields = [
			{ label: 'Username', field: 'username', regexp: /(user)|(login)/i },
			{ label: 'First Name', field: 'first_name', regexp: /first/i },
			{ label: 'Last Name', field: 'last_name', regexp: /last/i },
			{ label: 'Student ID', field: 'student_id', regexp: /stud/i },
			{ label: 'Email', field: 'email', regexp: /email/i },
			{ label: 'Section', field: 'section', regexp: /sect/i },
			{ label: 'Recitation', field: 'recitation', regexp: /recit/i },
			{ label: 'Role', field: 'role', regexp: /role/i } ];

		// use the first row to find the headers of the table (field names)
		// this is based on trying to match the needed field names to the know user
		// field names.
		const fillHeaders = () => {
			Object.keys(header_row.value).forEach((key) => {
				user_fields.forEach((field) => {
					if (field.regexp.test(`${header_row.value[key]}`)) {
						column_headers.value[key] = field.label;
					}
				});
			});
		};

		watch([column_headers], () => {
			// these are the defined columns in the table
			const def_cols = pick(column_headers.value, Object.keys(column_headers.value));

			// this is an object of the fields selected from the table
			const fields = pick(fromPairs(user_fields.map((obj) => [obj.label, obj.field])), values(def_cols));
			// mapping of column number to user field
			user_param_map.value =  invert(mapValues(def_cols, (obj)=>fields[obj]));
		},
		{ deep: true });

		watch([first_row_header], () => {
			selected.value = [];
			if(first_row_header.value) {
				const first_row = merged_users.value.shift();
				if (first_row) {
					header_row.value = first_row;
					fillHeaders();
				}
			} else {
				merged_users.value.unshift(header_row.value);
			}
		});

		watch([selected, user_param_map, common_role], () => {
			loading.value = true;
			merged_users_to_add.value = [];
			selected_user_error.value = false;
			users_already_in_course.value = false;

			// reset all of the errors
			filter(merged_users.value, ((u: UserFromFile) => u._error?.type !== 'none'))
				.forEach(u => {
					u._error = { // reset the error for each selected row
						type: 'none',
						message: ''
					};
				});

			selected.value.forEach((params: UserFromFile) => {
				let parse_error: ParseError|null = null;
				const row = parseInt(`${params?._row || -1}`);

				try {
					const merged_user = pick(mapValues(user_param_map.value, (obj) => params[obj]),
						Object.keys(newMergedUser()));
					if(use_single_role.value && common_role.value) {
						merged_user.role = common_role.value;
					}

					// if the user is already in the course, show a warning
					const u = store.state.users.merged_users.find(_u => _u.username === merged_user.username);
					if (u) {
						users_already_in_course.value = true;
						parse_error = {
							type: 'warn',
							message: `The user with username '${merged_user.username}'`
								+' is already enrolled in the course.',
							entire_row: true
						};
					} else {
						merged_users_to_add.value.push(parseMergedUser(merged_user));
					}
				} catch (error) {
					const err = error as ParseError;
					selected_user_error.value = true;
					const user_fields = Object.keys(newUser());
					const course_user_fields = Object.keys(newCourseUser());

					parse_error = {
						type: 'error',
						message: err.message
					};

					if (err.field === '_all') {
						assign(parse_error, { entire_row: true });
					} else if (err.field &&
						(user_fields.indexOf(err.field)>=0 || course_user_fields.indexOf(err.field)>=0)) {
						assign(parse_error, {
							col: user_param_map.value[err.field],
							entire_row: isUndefined(user_param_map.value[err.field])
						});
					} else if (isUndefined(err.field)) { // missing field
						assign(parse_error, { entire_row: true });
					}
				}

				if(parse_error) {
					const row_index = merged_users.value.findIndex((u: UserFromFile) => u._row === row);
					if (row_index >= 0) {
						const user = clone(merged_users.value[row_index]);
						user._error = parse_error;
						merged_users.value.splice(row_index, 1, user);
					}
				}
			});
			loading.value = false; // turn off the loading UI on table
		});

		const loadFile = () => {
			header_row.value = {};
			first_row_header.value = false; // reset the toggle when loading the file.
			const reader: FileReader = new FileReader();
			reader.readAsText(file.value);
			reader.onload = (evt: ProgressEvent) => {
				if (evt && evt.target) {
					const reader = evt.target as FileReader;
					const results = parse(reader.result as string, { header: false, skipEmptyLines: true });
					if (results.errors && results.errors.length > 0) {
						$q.notify({
							message: results.errors[0].message,
							color: 'red'
						});
					} else {
						const users: Array<UserFromFile> = [];
						const data = results.data as Array<Array<string>>;
						data.forEach((row: Array<string>, index: number) => {
							const d: UserFromFile = {};
							d._error =  {
								type: 'none',
								message: ''
							};
							d._row = index;
							row.forEach((v: string, i: number) => {
								d[`col${i+1}`] = v;
							});
							users.push(d);
						});
						merged_users.value = users;
					}
				}
			};
		};

		const addUsers = async () => {
			// console.log('in addUsers');

			for await (const _user of merged_users_to_add.value) {
				_user.course_id = store.state.session.course.course_id;
				try {
					const u = await store.dispatch('users/getUser', _user.username) as User;
					_user.user_id = u.user_id;
				} catch (err) {
					const error = err as ResponseError;
					// this will occur is the user is not a global user
					if (error.exception !== 'DB::Exception::UserNotFound') {
						logger.error(error.message);
					}
				}
				try {
					const merged_user = await store.dispatch('users/addMergedUser', _user) as MergedUser;
					$q.notify({
						message: `The user ${merged_user.first_name} ${merged_user.last_name}` +
							' was successfully added to the course.',
						color: 'green'
					});
					context.emit('closeDialog');
				} catch (err) {
					const error = err as AxiosError;
					logger.error(error);
					const data = error?.response?.data as ResponseError || { exception: '' };
					$q.notify({
						message: data.exception,
						color: 'red'
					});
				}

			}
		};
		const getColumns = () => {
			return merged_users.value.length === 0 ? [] :
				Object.keys(merged_users.value[0]).filter((v: string) => (v !== '_row' && v !== '_error'))
					.map((v) => ({ name: v, label: v, field: v }));
		};

		return {
			file,
			merged_users,
			selected,
			first_row_header,
			user_fields,
			column_headers,
			merged_users_to_add,
			selected_user_error,
			users_already_in_course,
			loading,
			loadFile,
			addUsers,
			use_single_role,
			common_role,
			roles: ref(['student', 'TA', 'instructor']),
			columns: computed(() => getColumns()),
			getErrorClass: (col_name: string, err: ParseError) => {
				if (col_name === err.col || err.entire_row) {
					return err.type === 'none' ?
						'' : (err.type === 'error') ? 'cell-error' : 'cell-warn';
				}
			},
			hasError(props: { col: {name: string}; row: { _error: ParseError }}) {
				return props.row._error.type !== 'none' &&
					(props.col.name === props.row._error.col || props.row._error.entire_row);
			}
		};
	}
});
</script>

<!-- Mainly this is needed to get a table with a sticky header -->

<style lang="scss">
table {
	.cell-error {
		background-color: rgb(248, 91, 91);
	}

	.cell-warn {
		background-color: rgb(247, 247, 162);
	}
}

.loaded-users-table {
	/* height or max-height is important */
	height: 510px;

	.q-table__top,
	.q-table__bottom,
	thead tr:first-child th {
		/* bg color is important for th; just specify one */
		background-color: #c1f4cd;
	}

	thead tr th {
		position: sticky;
		z-index: 1;
	}

	thead tr:first-child th {
		top: 0;
	}

	/* this is when the loading indicator appears */

	&.q-table--loading thead tr:last-child th {
		/* height of all previous header rows */
		top: 48px;
	}
}
</style>

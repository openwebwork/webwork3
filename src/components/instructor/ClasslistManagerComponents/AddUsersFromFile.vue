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
				<div class="row">
					<div class="col-3">
						<q-toggle v-model="first_row_header" :disable="merged_users.length==''"/>
						First row is Header
					</div>

					<div class="col-6" v-if="invalid_table_cells.length>0">
						<q-banner dense inline-actions class="text-white bg-red">
							There are validation errors with the loaded data.
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
							:pagination="{ rowsPerPage: 0}">

							<template v-slot:header-cell="props">
								<q-th :props="props">
									<q-select :options="user_fields.map( (f) => f.label)"
										v-model="column_headers[props.col.name]"/>
									{{ props.col.name }}
								</q-th>
							</template>

							<template v-slot:body-cell="props">
								<q-td :props="props" :class="hasError(props) ? 'bg-red-3': '' ">
									<span v-if="hasError(props)">  {{ props.value }}
										<q-badge color="red">?<q-tooltip>
											{{ getErrorText(props) }}
											</q-tooltip>
										</q-badge>
									</span>
									<span v-else> {{ props.value }} </span>
								</q-td>
							</template>
						</q-table>
					</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="Cancel" v-close-popup />
				<q-btn flat label="Add Users" @click="addUsers" />
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
import { newUser, parseMergedUser, newCourseUser } from 'src/store/utils/users';
import { pick, fromPairs, values, invert, mapValues } from 'lodash-es';

interface Prop {
	row: {
		_row: number;
	}
	col: {
		name: string;
	}
}

interface ParseError {
	row: number;
	col?: number;
	message: string;
	field?: string;
	entire_row?: boolean;
}

export default defineComponent({
	name: 'AddUsersFromFile',
	emits: ['closeDialog'],
	setup(props, context) {
		const store = useStore();
		const $q = useQuasar();
		const file: Ref<File> = ref(new File([], ''));
		const invalid_table_cells: Ref<Array<ParseError>> = ref([]);
		const merged_users: Ref<Array<Dictionary<string|number>>> = ref([]); // stores all users from the file
		const selected: Ref<Array<Dictionary<string|number>>> = ref([]); // stores the selected users
		const column_headers: Ref<Dictionary<string>> = ref({});
		const user_param_map: Ref<Dictionary<string>> = ref({}); // provides a map from column number to field name

		const first_row_header: Ref<boolean> = ref(false);
		const header_row: Ref<Dictionary<string|number>> = ref({});
		const merged_users_to_add: Ref<Array<MergedUser>> = ref([]);

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

		watch([selected], () => {
			merged_users_to_add.value = [];
			invalid_table_cells.value = [];
			selected.value.forEach((params) => {

				try {
					const user = pick(mapValues(user_param_map.value, (obj) => params[obj]), Object.keys(newUser()));
					merged_users_to_add.value.push(parseMergedUser(user));
				} catch (error) {
					const err = error as ParseError;
					const user_fields = Object.keys(newUser());
					const course_user_fields = Object.keys(newCourseUser());
					// if the error was a missing required field
					if (err.field === '_all') {
						invalid_table_cells.value.push({
							message: err.message,
							row: parseInt(`${params._row}`),
							entire_row: true
						});
					} else if (err.field &&
						(user_fields.indexOf(err.field)>=0 || course_user_fields.indexOf(err.field)>=0)) {
						invalid_table_cells.value.push({
							message: err.message,
							field: err.field,
							row: parseInt(`${params._row}`),
							col: parseInt(`${user_param_map.value[err.field]}`),
							entire_row: false
						});
					}
				}
			});
		});

		const loadFile = () => {
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
						const data = results.data as Array<Dictionary<string|number>>;
						data.forEach((row: Dictionary<string|number>, index: number) => { row['_row'] = index; });
						merged_users.value = data;
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
				Object.keys(merged_users.value[0]).filter((v) => v !== '_row')
					.map((v) => ({ name: v, label: v, field: v }));
		};

		return {
			file,
			merged_users,
			selected,
			invalid_table_cells,
			first_row_header,
			user_fields,
			column_headers,
			merged_users_to_add,
			loadFile,
			addUsers,
			columns: computed(() => getColumns()),
			hasError: (props: Prop) =>
				invalid_table_cells.value.find((error: ParseError) =>
				  error.entire_row && props.row._row === error.row ||
					props?.row?._row === error.row && parseInt(props.col.name) === error.col
				) ? true : false,
			getErrorText: (props: Prop) => {
				const err = invalid_table_cells.value.find((error: ParseError) =>
				  error.entire_row && props.row._row === error.row ||
					props?.row?._row === error.row && parseInt(props.col.name) === error.col
				);
				return err?.message;
			}
		};
	}
});
</script>

<!-- Mainly this is needed to get a table with a sticky header -->

<style lang="scss">
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

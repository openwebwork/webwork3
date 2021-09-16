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
						<q-btn @click="loadFile">Load File</q-btn>
					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="col-3">
						<q-toggle v-model="first_row_header" /> First row is Header
					</div>

					<div class="col-6" v-if="!validated">
						<q-banner dense inline-actions class="text-white bg-red">
							There are validation errors with the loaded data.
						</q-banner>
					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="q-pa-md" v-if="users.length > 0">
						<q-table class="loaded-users-table"
							:rows="users" row-key="_row" :columns="columns"
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
									{{ props.value }}
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

import { useStore } from 'src/store';
import type { Dictionary, User, CourseUser } from 'src/store/models';
import { newUser, parseUser, newCourseUser, parseCourseUser } from 'src/store/utils/users';
import { pick, fromPairs, values, invert, mapValues, omit } from 'lodash-es';

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
	col: number;
	message: string;
	field: string;
}

export default defineComponent({
	name: 'AddUsersFromFile',
	setup() {
		const store = useStore();
		const $q = useQuasar();
		const file: Ref<File> = ref(new File([], ''));
		const validated: Ref<boolean> = ref(true);  // true if all selected users validate
		const invalid_table_cells: Ref<Array<ParseError>> = ref([]);
		const users: Ref<Array<Dictionary<string|number>>> = ref([]); // stores all users from the file
		const selected: Ref<Array<Dictionary<string|number>>> = ref([]); // stores the selected users
		const column_headers: Ref<Dictionary<string>> = ref({});
		const user_param_map: Ref<Dictionary<string>> = ref({}); // provides a map from column number to field name

		const first_row_header: Ref<boolean> = ref(false);
		const header_row: Ref<Dictionary<string|number>> = ref({});
		const users_to_add: Ref<Array<User>> = ref([]);
		const course_users_to_add: Ref<Array<Dictionary<string|number>>> = ref([]);
		// const course_users_to_add: Ref<Array<CourseUser>> = ref([]);

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
				const first_row = users.value.shift();
				if (first_row) {
					header_row.value = first_row;
					fillHeaders();
				}
			} else {
				users.value.unshift(header_row.value);
			}
		});

		watch([selected], () => {
			validated.value = true;
			users_to_add.value = [];
			course_users_to_add.value = [];
			invalid_table_cells.value = [];
			selected.value.forEach((params) => {

				let user: Dictionary<string|number> = {};
				let course_user: Dictionary<string|number> = {};

				try {
					user = pick(mapValues(user_param_map.value, (obj) => params[obj]), Object.keys(newUser()));
					users_to_add.value.push(parseUser(user));

					course_user = pick(mapValues(user_param_map.value, (obj) => params[obj]),
						Object.keys(newCourseUser()));

					const parsed_course_user = parseCourseUser(course_user);
					course_user.username = user.username;

					parsed_course_user.role = parsed_course_user.role ?? 'student';
					course_users_to_add.value.push(parsed_course_user as unknown as
						Dictionary<string|number>);
				} catch (error) {
					const err = error as ParseError;
					validated.value = false;
					const user_fields = Object.keys(newUser());
					const course_user_fields = Object.keys(newCourseUser());
					if (user_fields.indexOf(err.field)>=0 || course_user_fields.indexOf(err.field)>=0){
						invalid_table_cells.value.push({
							message: err.message,
							field: err.field,
							row: parseInt(`${params._row}`),
							col: parseInt(`${user_param_map.value[err.field]}`)
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
					const results = parse(reader.result as string, { header: false });
					if (results.errors && results.errors.length > 0) {
						$q.notify({
							message: results.errors[0].message,
							color: 'red'
						});
					} else {
						const data = results.data as Array<Dictionary<string|number>>;
						data.forEach((row: Dictionary<string|number>, index: number) => { row['_row'] = index; });
						users.value = data;
					}
				}
			};
		};

		const addUsers = async () => {
			// console.log('in addUsers');

			for await (const _user of users_to_add.value) {
				const user = await store.dispatch('users/addUser', _user) as User;
				$q.notify({
					message: `The global user ${user.first_name} ${user.last_name} was successfully added.`,
					color: 'green'
				});
			}

			for await (const _course_user of course_users_to_add.value) {
				// need to look up the user_id
				const user = store.state.users.users.find((u) => u.username === _course_user.username);
				if (user) {

					const cu = parseCourseUser(omit(_course_user, 'username'));
					cu.user_id = user.user_id;
					await store.dispatch('users/addCourseUser', _course_user) as CourseUser;
					// need to verify that the result is the same.
					$q.notify({
						message: 'The course user  was successfully added.',
						color: 'green'
					});
				}
			}
		};

		const getColumns = () => {
			return users.value.length === 0 ? [] :
				Object.keys(users.value[0]).filter((v) => v !== '_row')
					.map((v) => ({ name: v, label: v, field: v }));
		};

		return {
			file,
			users,
			selected,
			validated,
			invalid_table_cells,
			first_row_header,
			user_fields,
			column_headers,
			users_to_add,
			course_users_to_add,
			loadFile,
			addUsers,
			columns: computed(() => getColumns()),
			hasError: (props: Prop) =>
				invalid_table_cells.value.find((error: ParseError) =>
					props?.row?._row === error.row && parseInt(props.col.name) === error.col
				) ? true : false
		};
	}
});
</script>

<!-- Mainly this is needed to get a table with a sticky header -->

<style lang="sass">
.loaded-users-table
	/* height or max-height is important */
	height: 510px

	.q-table__top,
	.q-table__bottom,
	thead tr:first-child th
		/* bg color is important for th; just specify one */
		background-color: #c1f4cd

	thead tr th
		position: sticky
		z-index: 1

	thead tr:first-child th
		top: 0

	/* this is when the loading indicator appears */

	&.q-table--loading thead tr:last-child th
		/* height of all previous header rows */
		top: 48px
</style>

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
						<q-btn @click="loadFile" :disable="file.name === ''">Load File</q-btn>
					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row" v-if="course_users.length !== 0">
					<div class="col-3">
						<q-toggle v-model="first_row_header" />
						First row is Header
					</div>
					<div class="col-3">
						<q-toggle v-model="use_single_role" /> Import All users as
					</div>
					<div class="col-3">
						<q-select
							:disable="!use_single_role"
							:options="roles"
							v-model="common_role"
							label="Select Role"
							:options-dense="true"
						/>
					</div>
				</div>
				<div class="row">
					<div class="col-5 q-pa q-ma-lg" v-show="selected_user_error">
						<q-banner dense inline-actions class="text-white bg-red rounded-borders">
							There are validation errors with the loaded data. Any data row with an error
							will not be added.
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
					<div class="col-12 q-pa-md" v-if="course_users.length > 0">
						<q-table
							class="loaded-users-table"
							:rows="course_users"
							row-key="_row"
							:columns="columns"
							v-model:selected="selected_users"
							selection="multiple"
							:pagination="{ rowsPerPage: 0 }"
							:loading="loading"
						>
							<template v-slot:header-cell="props">
								<q-th :props="props">
									<q-select
										:options="user_fields.map((f) => f.label)"
										v-model="column_headers[props.col.name]"
									/>
								</q-th>
							</template>

							<template v-slot:body-cell="props">
								<q-td :class="getErrorClass(props.col.name, props.row._error)">
									<span v-if="hasError(props)">
										{{ props.value }}
										<q-badge color="black" v-if="props.row._error.type === 'error'"
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
				<q-btn
					flat
					:label="`Add ${course_users_to_add.length} Users and Close`"
					@click="addMergedUsers"
				/>
			</q-card-actions>
		</q-card>
	</div>
</template>

<script setup lang="ts">
import { ref, computed, watch, defineEmits } from 'vue';
import { useQuasar } from 'quasar';
import { parse } from 'papaparse';
import { AxiosError } from 'axios';
import { logger } from 'boot/logger';

import { useUserStore } from 'src/stores/users';
import { useSessionStore } from 'src/stores/session';
import type { Dictionary } from 'src/common/models';
import type { ResponseError } from 'src/common/api-requests/errors';
import { CourseUser, User, ParseableCourseUser } from 'src/common/models/users';
import { invert } from 'src/common/utils';
import { checkIfUserExists } from 'src/common/api-requests/user';
import { usePermissionStore } from 'src/stores/permissions';

interface ParseError {
	type: string;
	col?: string;
	message: string;
	field?: string;
	entire_row?: boolean;
}

type UserFromFile = {
	_row?: number;
	_error?: ParseError;
} & Dictionary<string>;

const emit = defineEmits(['closeDialog']);

const users = useUserStore();
const session = useSessionStore();
const permission_store = usePermissionStore();
const $q = useQuasar();

const file = ref<File>(new File([], ''));
// Stores all users from the file as well as parsing errors.
const course_users = ref<Array<UserFromFile>>([]);
// Stores the selected users.
const selected_users = ref<Array<UserFromFile>>([]);
const column_headers = ref<Dictionary<string>>({});
// Provides a map from column number to field name. It doesn't need to be reactive.
const user_param_map: Dictionary<string> = {};
const use_single_role = ref<boolean>(false);
const common_role = ref<string | null>(null);
const loading = ref<boolean>(false); // used to indicate parsing is occurring

const first_row_header = ref<boolean>(false);
const header_row = ref<UserFromFile>({});
const course_users_to_add = ref<Array<CourseUser>>([]);
const selected_user_error = ref<boolean>(false);
const users_already_in_course = ref<boolean>(false);

const user_fields = [
	{ label: 'Username', field: 'username', regexp: /(user)|(login)/i },
	{ label: 'First Name', field: 'first_name', regexp: /first/i },
	{ label: 'Last Name', field: 'last_name', regexp: /last/i },
	{ label: 'Student ID', field: 'student_id', regexp: /stud/i },
	{ label: 'Email', field: 'email', regexp: /email/i },
	{ label: 'Section', field: 'section', regexp: /sect/i },
	{ label: 'Recitation', field: 'recitation', regexp: /recit/i },
	{ label: 'Role', field: 'role', regexp: /role/i },
];

// Return an array of the roles in the course.
const roles = computed(() => permission_store.roles);

// use the first row to find the headers of the table (field names)
// this is based on trying to match the needed field names to the know user
// field names.
const fillHeaders = () => {
	Object.keys(header_row.value).forEach((key) => {
		user_fields.forEach((field: { regexp: RegExp; label: string; field: string }) => {
			if (field.regexp.test(`${header_row.value[key]}`)) {
				column_headers.value[key] = field.label;
				user_param_map[key] = field.field;
			}
		});
	});
};

// This converts converts each selected row to a ParseableCourseUser
// based on the column headers.
const getCourseUser = (row: UserFromFile) => {
	// The following pulls the keys out from the user_param_map and the the values out of row
	// to get the merged user.
	const course_user = Object.entries(user_param_map).reduce(
		(acc, [k, v]) => ({ ...acc, [v]: row[k as keyof UserFromFile] }),
		{}
	) as ParseableCourseUser;
	// Set the role if a common role for all users is selected_users.
	course_user.role = use_single_role.value ? common_role.value ?? 'UNKOWN' : 'UNKNOWN';
	return course_user;
};

// Parse the selected users from the file.
const parseUsers = () => {
	// Clear Errors and reset reactive variables.
	loading.value = true;
	course_users_to_add.value = [];
	selected_user_error.value = false;
	users_already_in_course.value = false;
	course_users.value
		.filter((u: UserFromFile) => u._error?.type !== 'none')
		.forEach((u) => {
			// reset the error for each selected row
			u._error = {
				type: 'none',
				message: '',
			};
		});

	// This is needed for parsing errors.
	const inverse_param_map = invert(user_param_map) as Dictionary<string>;

	selected_users.value.forEach((params: UserFromFile) => {
		let parse_error: ParseError | null = null;
		const row = parseInt(`${params?._row || -1}`);
		const course_user_params = getCourseUser(params);
		// If the user is already in the course, show a warning
		const u = users.course_users.find((_u) => _u.username === course_user_params.username);
		if (u) {
			users_already_in_course.value = true;
			parse_error = {
				type: 'warn',
				message:
					`The user with username '${course_user_params.username ?? ''}'` +
					' is already enrolled in the course.',
				entire_row: true,
			};
		} else {
			const course_user = new CourseUser(course_user_params);
			if (course_user.isValid()) {
				course_users_to_add.value.push(course_user);
			} else {
				const validate = course_user.validate();
				// Find the field which didn't validate.
				try {
					Object.entries(validate).forEach(([k, v]) => {
						if (typeof v === 'string') {
							throw {
								message: v,
								field: k,
							};
						}
					});
				} catch (error) {
					const err = error as ParseError;
					selected_user_error.value = true;

					parse_error = {
						type: 'error',
						message: err.message,
					};

					if (err.field === '_all') {
						Object.assign(parse_error, { entire_row: true });
					} else if (
						err.field &&
						(User.ALL_FIELDS.indexOf(err.field) >= 0 ||
							CourseUser.ALL_FIELDS.indexOf(err.field) >= 0)
					) {
						if (inverse_param_map[err.field]) {
							parse_error.col = inverse_param_map[err.field];
						} else {
							parse_error.entire_row = true;
						}
					} else if (err.field != undefined) {
						// missing field
						parse_error.entire_row = true;
					}
				}
			}
		}

		if (parse_error) {
			const row_index = course_users.value.findIndex((u: UserFromFile) => u._row === row);
			if (row_index >= 0) {
				// Copy the user, update and splice in.  This is needed to make the load file table reactive.
				const user = { ...course_users.value[row_index] };
				user._error = parse_error;
				course_users.value.splice(row_index, 1, user);
			}
		}
	});
	loading.value = false; // turn off the loading UI on table
};

const loadFile = () => {
	// Reset the header row and UI toggle when loading the file.
	header_row.value = {};
	first_row_header.value = false;
	logger.debug(`Loading file--${file.value.name}`);

	const reader: FileReader = new FileReader();
	reader.readAsText(file.value);
	reader.onload = (evt: ProgressEvent) => {
		if (evt && evt.target) {
			const reader = evt.target as FileReader;
			const results = parse(reader.result as string, {
				header: false,
				skipEmptyLines: true,
			});
			if (results.errors && results.errors.length > 0) {
				$q.notify({
					message: results.errors[0].message,
					color: 'red',
				});
			} else {
				const users: Array<UserFromFile> = [];
				const data = results.data as Array<Array<string>>;
				data.forEach((row: Array<string>, index: number) => {
					const d: UserFromFile = {};
					d._error = {
						type: 'none',
						message: '',
					};
					d._row = index;
					row.forEach((v: string, i: number) => {
						d[`col${i + 1}`] = v;
					});
					users.push(d);
				});
				course_users.value = users;
			}
		}
	};
};

// Add the Merged Users to the course.
const addMergedUsers = async () => {
	for await (const user of course_users_to_add.value) {
		user.course_id = session.course.course_id;

		// First check if the user is a global user.  If not, add the global user.
		await checkIfUserExists(session.course.course_id, user.username ?? '').then(async (global_user) => {
			if (global_user.username == undefined) {
				await users.addUser(new User(user)).then(u => {
					const msg =  `The global user with username '${u?.username ?? 'UNKNOWN'}'` +
							' was successfully added to the course.';
					logger.debug(`[addUsersFromFile]: ${msg}`);
					$q.notify({ message: msg, color: 'green' });
					user.user_id = u?.user_id ?? 0;
				}).catch(e => {
					const error = e as ResponseError;
					logger.error(`[addUsersFromFile]: ${error.message}`);
					$q.notify({ message: error.message, color: 'red' });
				});

			} else {
				user.user_id = parseInt(`${global_user.user_id ?? 0}`);
			}

			// Now add the user as a course user.
			users.addCourseUser(new CourseUser(user)).then(user => {
				const full_name = `${user.first_name} ${user.last_name}`;
				const msg = `The user ${full_name} was successfully added to the course.`;
				logger.debug(`[addUsersFromFile]: ${msg}`);
				$q.notify({ message: msg, color: 'green' });
				emit('closeDialog');
			}).catch(err => {
				const error = err as AxiosError;
				logger.error(`[addUsersFromFile]: ${error.toString()}`);
				const data = error?.response?.data as ResponseError || { exception: '' };
				$q.notify({
					message: data.exception,
					color: 'red'
				});
			});
		});
	}
};

watch([selected_users, common_role], parseUsers, { deep: true });

watch(
	() => column_headers,
	() => {
		// Update the user_param_map if the column headers change.
		Object.keys(column_headers.value).forEach((key) => {
			const user_field = user_fields.find(
				(obj) => obj.label === column_headers.value[key]
			);
			if (user_field) {
				user_param_map[key] = user_field.field;
			}
		});
		// And then reparse the file.
		parseUsers();
	},
	{ deep: true }
);

watch([first_row_header], () => {
	selected_users.value = [];
	if (first_row_header.value) {
		const first_row = course_users.value.shift();
		if (first_row) {
			header_row.value = first_row;
			fillHeaders();
		}
	} else {
		course_users.value.unshift(header_row.value);
	}
});

const columns = computed(() => {
	return course_users.value.length === 0
		? []
		: Object.keys(course_users.value[0])
			.filter((v: string) => v !== '_row' && v !== '_error')
			.map((v) => ({ name: v, label: v, field: v }));
});

const getErrorClass = (col_name: string, err: ParseError) => {
	if (col_name === err.col || err.entire_row) {
		return err.type === 'none' ? '' : err.type === 'error' ? 'cell-error' : 'cell-warn';
	}
};

const hasError = (props: { col: { name: string }; row: { _error: ParseError } }) =>
	props.row._error.type !== 'none' &&
		(props.col.name === props.row._error.col || props.row._error.entire_row);
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

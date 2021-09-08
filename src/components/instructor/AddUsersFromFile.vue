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

					<div class="col-6">

					</div>
				</div>
			</q-card-section>
			<q-card-section class="q-pt-none">
				<div class="row">
					<div class="q-pa-md" v-if="users.length > 0">
						<q-table class="loaded-users-table"
							:rows="users" row-key="row" :columns="columns"
							v-model:selected="selected" selection="multiple"
							:pagination="{ rowsPerPage: 0}">

							<template v-slot:header-cell="props">
								<q-th :props="props">
									<q-select :options="user_fields" v-model="colheader[props.col.name]"/>
									{{ props.col.name }}
								</q-th>
							</template>
						</q-table>
						</div>
				</div>
			</q-card-section>

			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="OK" v-close-popup />
			</q-card-actions>
		</q-card>
	</div>
</template>

<script lang="ts">
import { defineComponent, ref, Ref, computed, watch } from 'vue';
import { useQuasar } from 'quasar';
import { parse } from 'papaparse';
import { Dictionary } from 'src/store/models';

export default defineComponent({
	name: 'AddUsersFromFile',
	setup() {
		const $q = useQuasar();
		const file: Ref<File> = ref(new File([], ''));
		const users: Ref<Array<Dictionary<string|number>>> = ref([]);
		const selected: Ref<Array<Dictionary<string|number>>> = ref([]);
		const colheader: Ref<Dictionary<string>> = ref({});
		const first_row_header: Ref<boolean> = ref(false);
		const header_row: Ref<Dictionary<string|number>> = ref({});

		watch(() => first_row_header, () => {
			console.log('in watch');
			if(first_row_header.value) {
				const first_row = users.value.shift();
				if (first_row) {
					header_row.value = first_row;
				}
			} else {
				users.value.unshift(header_row.value);
			}
		});

		return {
			file,
			users,
			selected,
			first_row_header,
			user_fields: ['Username', 'First Name', 'Last Name'],
			colheader,
			loadFile: () => {
				console.log('in loadfile');
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
							data.forEach((row, index) => {row['row'] = index;});
							users.value = data;
						}
					}
				};
			},
			columns: computed(() => users.value.length === 0 ? [] :
				Object.keys(users.value[0]).map((v) => ({ name: v, label: v, field: v })))
		};
	}
});
</script>

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

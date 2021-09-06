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
				<div class="row">
					<div class="q-pa-md" v-if="users.length > 0">
						<q-table class="loaded-users-table"
							:rows="users" row-key="row" :columns="columns"
							v-model:selected="selected" selection="multiple"
							:pagination="{ rowsPerPage: 0}"
							/>
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
import { defineComponent, ref, Ref, computed } from 'vue';
import { useQuasar } from 'quasar';
import { parse } from 'papaparse';
import { CourseUser, Dictionary } from 'src/store/models';

export default defineComponent({
	name: 'AddUsersFromFile',
	setup() {
		const $q = useQuasar();
		const file: Ref<File> = ref(new File([], ''));
		const users: Ref<Array<Dictionary<string|number>>> = ref([]);
		const selected: Ref<Array<Dictionary<string|number>>> = ref([]);

		return {
			file,
			users,
			selected,
			columns: computed(() => users.value.length === 0 ? [] :
				Object.keys(users.value[0])
					.map((v) => ({ name: v, label: v, field: v }))),
			loadFile: () => {
				const reader: FileReader = new FileReader();
				reader.readAsText(file.value);
				reader.onload = (evt: ProgressEvent) => {
					if (evt && evt.target) {
						const reader = evt.target as FileReader;
						const results = parse(reader.result as string, {header: true});
						if (results.errors && results.errors.length > 0) {
							console.log(results.errors);
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
			}
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

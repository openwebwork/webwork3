<template>
	<q-page class="q-pa-md">
		<div class="q-gutter-y-md">
			<q-card>
				<q-tabs
					v-model="tab"
					dense
					class="text-grey"
					active-color="primary"
					indicator-color="primary"
					align="justify"
					narrow-indicator
				>
					<q-tab v-for="category in categories" :name="category" :label="category" :key="category" />
				</q-tabs>

				<q-separator />

				<q-tab-panels v-model="tab" animated>
					<q-tab-panel v-for="category in categories" :name="category" :key="'panel:' + category">
						<q-markup-table separator="horizontal" dense>
							<template v-for="item in getSettings(category)" :key="item.setting_name">
								<single-setting :setting="item" />
							</template>
						</q-markup-table>
					</q-tab-panel>
				</q-tab-panels>
			</q-card>
		</div>
	</q-page>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue';
import { useSettingsStore } from 'src/stores/settings';
import SingleSetting from 'src/components/instructor/SingleSetting.vue';

const settings_store = useSettingsStore();
const tab = ref('general');

const categories = computed(() => [
	...new Set(settings_store.course_settings.map(setting => setting.category))
]);

const getSettings = (cat: string) => settings_store.getSettingsByCategory(cat);

</script>

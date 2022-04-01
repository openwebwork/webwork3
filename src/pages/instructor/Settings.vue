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
							<template v-for="item in getSettings(category)" :key="item.var">
								<single-setting :setting="item" :value="getSettingValue(item.var)" />
							</template>
						</q-markup-table>
					</q-tab-panel>
				</q-tab-panels>
			</q-card>
		</div>
	</q-page>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';
import { useSettingsStore } from 'src/stores/settings';
import type { CourseSettingInfo } from 'src/common/models/settings';
import SingleSetting from 'src/components/instructor/SingleSetting.vue';

export default defineComponent({
	name: 'Settings',
	components: {
		SingleSetting
	},
	setup() {
		const settings = useSettingsStore();
		const tab = ref('');

		// Needed if you start on this page.
		watch(() => settings.course_settings, () => {
			tab.value = 'general';
		});

		return {
			tab,
			categories: computed(() => [
				...new Set(settings.default_settings.map((setting: CourseSettingInfo) => setting.category))
			]),
			getSettings: (cat: string) =>
				settings.default_settings.filter((setting: CourseSettingInfo) => setting.category === cat),
			getSettingValue: (var_name: string) => settings.getCourseSetting(var_name).value
		};
	}
});
</script>

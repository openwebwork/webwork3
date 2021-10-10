<template>
	<div class="q-pa-md">
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
	</div>
</template>

<script lang="ts">
import { defineComponent, computed, ref } from 'vue';
import { useStore } from 'src/store';
import { CourseSettingInfo, CourseSetting } from 'src/store/models/settings';
import SingleSetting from './SingleSetting.vue';

export default defineComponent({
	name: 'Settings',
	components: {
		SingleSetting
	},
	setup() {
		const store = useStore();
		const tab = ref('general');

		return {
			tab,
			categories: computed(() => [
				...new Set(store.state.settings.default_settings.map((setting: CourseSettingInfo) => setting.category))
			]),
			getSettings: (cat: string) =>
				store.state.settings.default_settings.filter((setting: CourseSettingInfo) => setting.category === cat),
			getSettingValue: (var_name: string) => {
				const settings = store.state.settings.course_settings.filter(
					(setting: CourseSetting) => setting.var === var_name
				);
				return settings[0].value;
			}
		};
	}
});
</script>

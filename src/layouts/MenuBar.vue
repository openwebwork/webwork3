<template>
	<div>
	<q-header>
		<div class="row">
			<div class="col col-md-3 col-12 q-my-auto" style="background-color:#1048ae">
				<q-toolbar>
					<q-btn flat @click="$emit('toggle-menu')" round dense icon="menu" />
					<q-toolbar-title>
						<q-img src="images/webwork_logo.svg" position="0 50%" width="190px" fit="scale-down" />
					</q-toolbar-title>
				</q-toolbar>
			</div>
			<div class="col col-md-4 col-12 q-my-auto" style="padding:4px 0">
				<q-img src="images/maa_logo.png" position="6px 50%" width="340px" fit="scale-down" :ratio="9.5" />
			</div>
			<div class="col col-md-5 col-12 q-my-auto">
				<q-toolbar>
					<q-space />
					<q-btn-dropdown v-if="logged_in" color="secondary" icon="person" :label="full_name">
						<q-list>
							<q-item clickable v-close-popup @click="open_user_settings = true">
								{{ $t('menu_bar.user_settings') }}
							</q-item>
							<q-item clickable v-close-popup @click="logout">{{ $t('authentication.logout') }}</q-item>
						</q-list>
					</q-btn-dropdown>
					<q-btn-dropdown color="secondary" :label="current_course_name" v-if="current_course_name"
						style="margin-left:6px">
						<q-list>
							<template v-for="course in user_courses" :key="course.course_id">
								<q-item clickable v-close-popup
									@click="changeCourse(course.course_id, course.course_name)">
									<q-item-section>
										<q-item-label>{{course.course_name}}</q-item-label>
									</q-item-section>
								</q-item>
							</template>
						</q-list>
					</q-btn-dropdown>
					<q-btn flat @click="$emit('toggle-sidebar')" round dense icon="vertical_split" class="q-ml-xs" />
				</q-toolbar>
			</div>
		</div>
	</q-header>
	<q-dialog medium v-model="open_user_settings">
		<q-card style="width: 300px">
			<q-card-section>
				<div class="text-h6">{{ $t('menu_bar.user_settings') }}</div>
			</q-card-section>

			<q-card-section class="q-pt-none">
				<q-select label="Language" v-model="currentLocale" :options="availableLocales" emit-value map-options
					@update:model-value="setI18nLanguage" />
			</q-card-section>
			<q-card-actions align="right" class="bg-white text-teal">
				<q-btn flat label="OK" v-close-popup />
			</q-card-actions>
		</q-card>
	</q-dialog>
	</div>
</template>

<script lang="ts">
import { computed, defineComponent, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useRoute } from 'vue-router';
import { endSession } from 'src/common/api-requests/session';
import { useI18n } from 'vue-i18n';
import { setI18nLanguage } from 'boot/i18n';
import { useSessionStore } from 'src/stores/session';
import { useUserStore } from 'src/stores/users';
import { useSettingsStore } from 'src/stores/settings';

export default defineComponent({
	name: 'MenuBar',
	emits: ['toggle-menu', 'toggle-sidebar'],
	setup() {
		const session = useSessionStore();
		const users = useUserStore();
		const settings = useSettingsStore();
		const router = useRouter();
		const route = useRoute();
		const current_view = ref('');
		const currentLocale = ref(useI18n({ useScope: 'global' }).locale.value);

		const current_course_name = computed(() => session.course.course_name);

		return {
			logged_in: computed(() => session.logged_in),
			user: computed(() => session.user),
			current_course_name,
			full_name: computed(() => session.full_name),
			user_courses: computed(() =>
				users.user_courses.filter(course => course.course_name !== current_course_name.value)),
			changeCourse: (course_id: number, course_name: string) => {
				const current_course = users.user_courses
					.find(course => course.course_name === current_course_name.value);

				const new_course = users.user_courses.find(course => course.course_name === course_name);
				if (current_course && new_course && current_course.role !== new_course.role) {
					void router.push({ name: new_course.role, params: { course_id: course_id } });
				}
				void session.setCourse({ course_name, course_id });
			},
			currentLocale,
			availableLocales: computed(() => {
				return settings.getCourseSetting('languages').value as string[];
			}),
			setI18nLanguage,
			open_user_settings: ref(false),
			current_view,
			logout: async () => {
				await endSession();
				void session.logout();
				void router.push('/login');
			},
			menubar_color: computed(() =>
				/^\/courses\/\d+\/instructor/.test(route.path)
					? 'deep-purple-8'
					: /^\/admin/.test(route.path)
						? 'indigo-8'
						: 'green-9'
			)
		};
	}
});
</script>

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

<script setup lang="ts">
import { computed, defineEmits, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

import { setI18nLanguage } from 'boot/i18n';
import { logger } from 'src/boot/logger';

import { endSession } from 'src/common/api-requests/session';
import { useSessionStore } from 'src/stores/session';
import { useSettingsStore } from 'src/stores/settings';

import type { CourseSettingInfo } from 'src/common/models/settings';
import { UserRole } from 'src/common/models/parsers';

defineEmits(['toggle-menu', 'toggle-sidebar']);
const session = useSessionStore();
const settings = useSettingsStore();
const router = useRouter();
const open_user_settings = ref(false);
const currentLocale = ref(useI18n({ useScope: 'global' }).locale.value);
const current_course_name = computed(() => session.course.course_name);
const logged_in = computed(() => session.logged_in);
const full_name = computed(() => session.full_name);
const user_courses = computed(() =>
	session.user_courses.filter(course => course.course_name !== current_course_name.value));

const changeCourse = (course_id: number, course_name: string) => {
	const new_course = session.user_courses.find(course => course.course_name === course_name);

	// This sets the path to the instructor or student dashboard.
	const role = new_course?.role === UserRole.instructor ?
		'instructor' : new_course?.role === UserRole.student ? 'student' : 'UNKNOWN';

	if (new_course != undefined) {
		router.push(`/courses/${new_course.course_id}/${role}`).then(() => {
			session.setCourse({
				course_name: new_course.course_name,
				course_id: new_course.course_id
			});
		}).catch(() => {
			logger.error('[MenuBar/changeCourse]: Error occurred.');
		});
	}
};

const availableLocales = computed(() =>
	settings.default_settings.find((setting: CourseSettingInfo) => setting.var === 'language')?.options
);

const logout = async () => {
	await endSession();
	void session.logout();
	void router.push('/login');
};
</script>

<template>
	<header class="col" style="position: sticky">
		<div class="row">
			<div class="col-3 text-h6">Open Problem Library </div>
			<div v-if="section" class="col-3 vertical-middle">
				<q-btn @click="loadProblems">Load Problems</q-btn>
			</div>
		</div>
		<div class="row">
			<div class="col-3">
				<q-select
					:options="disciplines"
					v-model="discipline"
					option-label="name"
					label="Select a Discipline" />
			</div>
			<div class="col-3" >
				<q-select v-if="subjects.length > 0"
					:options="subjects"
					v-model="subject"
					option-label="name"
					label="Select a Subject" />
			</div>
			<div class="col-3">
				<q-select
					v-if="chapters.length > 0"
					:options="chapters"
					option-label="name"
					v-model="chapter" label="Select a Chapter" />
			</div>
			<div class="col-3">
				<q-select
					v-if="sections.length > 0"
					:options="sections"
					option-label="name"
					v-model="section" label="Select a Section" />
			</div>
		</div>
	</header>
	<div v-if="problems.length > 0" class="col">
		<div v-for="problem in problems" :key="problem.problem_number">
			<problem
				:problem="problem"
				class="q-mb-md"
				@add-problem="addProblem(problem)"
			/>
		</div>
	</div>
</template>

<script lang="ts">

import { defineComponent, ref, watch } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from 'src/store';
import { LibraryProblem } from 'src/store/models/problems';
import { ResponseError } from 'src/store/models';
import Problem from 'components/common/Problem.vue';
import { fetchDisciplines, fetchChapters, fetchSubjects, fetchSections, fetchLibraryProblems, LibraryCategory }
	from 'src/common/api-requests/library';
import { logger } from 'boot/logger';

export default defineComponent({
	name: 'LibPanelOpl',
	components: {
		Problem
	},
	setup() {
		logger.debug('in setup()');
		const $q = useQuasar();
		const store = useStore();
		const discipline = ref<LibraryCategory | null>(null); // start with the select field to be empty.
		const disciplines = ref<Array<LibraryCategory>>([]);
		const subject = ref<LibraryCategory | null>(null);
		const subjects = ref<Array<LibraryCategory>>([]);
		const chapter = ref<LibraryCategory | null>(null);
		const chapters = ref<Array<LibraryCategory>>([]);
		const section = ref<LibraryCategory | null>(null);
		const sections = ref<Array<LibraryCategory>>([]);
		const problems = ref<Array<LibraryProblem>>([]);

		void fetchDisciplines().then(val => {
			disciplines.value = val;
		});

		watch([discipline], async () => {
			subjects.value = [];
			chapters.value = [];
			sections.value = [];
			subject.value = chapter.value = section.value = null;

			if (discipline.value) {
				await fetchSubjects({ disc_id: discipline.value.id }).then(val => {
					subjects.value = val;
				});
			}
		});

		watch([subject], async () => {
			chapters.value = [];
			sections.value = [];

			if (discipline.value && subject.value) {
				await fetchChapters({
					disc_id: discipline.value.id,
					subj_id: subject.value.id
				}).then(val => {
					chapters.value = val;
					section.value = null;
				});
			}
		});

		watch([chapter], async () => {
			sections.value = [];

			if (discipline.value && subject.value && chapter.value) {
				await fetchSections({
					disc_id: discipline.value.id,
					subj_id: subject.value.id,
					chap_id: chapter.value.id
				}).then(val => {
					sections.value = val;
				});
			}
		});

		return {
			discipline,
			disciplines,
			subject,
			subjects,
			chapter,
			chapters,
			section,
			sections,
			problems,
			loadProblems: async () => {
				logger.debug('[LibPanelOPL/loadProblems] dispatching request to store');
				if (discipline.value && subject.value && chapter.value && section.value) {
					await fetchLibraryProblems({
						disc_id: discipline.value.id,
						subj_id: subject.value.id,
						chap_id: chapter.value.id,
						sect_id: section.value.id
					}).then(val => {problems.value = val;});
				}
			},
			addProblem: async (prob: LibraryProblem) => {
				const set_id = store.state.app_state.library_state.target_set_id;
				if (set_id == 0) {
					alert('You must select a target problem set');
				} else {
					const course_id = store.state.session.course.course_id;
					try {
						await store.dispatch('problem_sets/addSetProblem', { set_id, course_id,
							problem: prob
						});
						$q.notify({
							message: 'A problem was added to the target set.',
							color: 'green'
						});

					} catch (err) {
						const error = err as ResponseError;
						$q.notify({ message: error.message, color: 'red' });
					}
					logger.debug(`[LibPanelOPL/addProblem] set_id: ${set_id};` +
						` added: ${JSON.stringify(prob.toObject())}`);
				}
			}
		};
	}
});
</script>

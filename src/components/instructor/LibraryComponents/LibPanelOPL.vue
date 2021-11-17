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
				<q-select :options="disciplines" v-model="discipline" label="Select a Discipline" />
			</div>
			<div class="col-3" >
				<q-select v-if="subjects.length > 0"
					:options="subjects"
					v-model="subject" label="Select a Subject" />
			</div>
			<div class="col-3">
				<q-select
					v-if="chapters.length > 0"
					:options="chapters"
					v-model="chapter" label="Select a Chapter" />
			</div>
			<div class="col-3">
				<q-select
					v-if="sections.length > 0"
					:options="sections"
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

import { defineComponent, ref, computed, watch } from 'vue';
import { useQuasar } from 'quasar';

import { useStore } from 'src/store';
import { LibraryProblem } from 'src/store/models/set_problem';
import { ResponseError } from 'src/store/models';
import Problem from 'components/common/Problem.vue';
import { logger } from 'boot/logger';

interface SelectItem {
	label?: string;
	name?: string;
	crossref?: number;
	id: number;
}

export default defineComponent({
	name: 'LibPanelOpl',
	components: {
		Problem
	},
	setup() {
		const $q = useQuasar();
		const store = useStore();
		const discipline = ref<SelectItem | null>(null); // start with the select field to be empty.
		const subject = ref<SelectItem | null>(null);
		const chapter = ref<SelectItem | null>(null);
		const section = ref<SelectItem | null>(null);

		watch([discipline], async () => {
			void store.dispatch('library/resetSections');
			void store.dispatch('library/resetChapters');
			void store.dispatch('library/resetSubjects');
			const d = discipline.value;
			subject.value = chapter.value = section.value = null;
			await store.dispatch('library/fetchSubjects', { disc_id: d?.id });
		});

		watch([subject], async () => {
			void store.dispatch('library/resetSections');
			void store.dispatch('library/resetChapters');
			const subj = subject.value;
			const d = discipline.value;
			chapter.value = section.value = null;
			await store.dispatch('library/fetchChapters', { disc_id: d?.id, subj_id: subj?.id });
		});

		watch([chapter], async () => {
			void store.dispatch('library/resetSections');
			const ch = chapter.value;
			const subj = subject.value;
			const d = discipline.value;
			section.value = null;
			await store.dispatch('library/fetchSections',
				{
					disc_id: d?.id, subj_id: subj?.id, chap_id: ch?.id
				}
			);
		});

		watch(() => store.state.app_state.library_state.target_set_id, () => {
			logger.debug(`[LibPanelOPL] update target set: ${store.state.app_state.library_state.target_set_id}`);
		});

		const getLabelId = (item: SelectItem): SelectItem =>  ({ label: item.name, id: item.crossref ?? item.id });

		return {
			discipline,
			disciplines: computed(() => store.state.library.disciplines.map(getLabelId)),
			subject,
			subjects: computed(() => store.state.library.subjects.map(getLabelId)),
			chapter,
			chapters: computed(() => store.state.library.chapters.map(getLabelId)),
			section,
			sections: computed(() => store.state.library.sections.map(getLabelId)),
			problems: computed(() => store.state.library.problems),
			loadProblems: async () => {
				const sect = section.value;
				logger.debug('[LibPanelOPL/loadProblems] dispatching request to store');
				await store.dispatch('library/fetchLibraryProblems', { sect_id: sect?.id });
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
	},
	async beforeMount() {
		const store = useStore();
		logger.debug('resetting OPL dropdowns and fetching Disciplines...');

		void store.dispatch('library/resetSections');
		void store.dispatch('library/resetChapters');
		void store.dispatch('library/resetSubjects');
		void store.dispatch('library/resetProblems');

		await store.dispatch('library/fetchDisciplines');
	}
});
</script>

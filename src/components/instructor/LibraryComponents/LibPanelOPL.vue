<template>
	<div class="row">
		<div class="col-3 text-h6">Open Problem Library </div>
		<div class="col-3 offset-6">
			<q-select :options="disciplines" v-model="discipline" label="Select a Discipline" />
		</div>
	</div>
	<div class="row">
		<div class="col-3" >
			<q-select v-if="subjects.length > 0"
				:options="subjects"
				v-model="subject" label="Select a Subject" />
		</div>
		<div class="col-3">
			<q-select
				 v-if="chapters.length > 0 "
				 :options="chapters"
				 v-model="chapter" label="Select a Chapter" />
		</div>
		<div class="col-3">
			<q-select
				v-if="sections.length > 0 "
				:options="sections"
				v-model="section" label="Select a Section" />
		</div>
		<div class="col-3 vertical-middle">
			<q-btn @click="loadProblems">Load Problems</q-btn>
		</div>
	</div>
	<div v-if="problems.length >0" class="scroll" style="height: 500px">
		<problem
			v-for="(problem,index) in problems"
			:sourceFilePath="problem.file_path"
			:key="problem.id"
			:problemPrefix="`QUESTION_${index + 1}_`"
			class="q-mb-md"
			type="library"
			@add-problem="addProblem(problem)"
			/>
	</div>
</template>

<script lang="ts">
import axios from 'axios';
import { api } from 'boot/axios';

import type { Ref } from 'vue';
import { defineComponent, ref, computed, watch } from 'vue';
import { useStore } from 'src/store';
// import { Discipline, LibrarySubject } from 'src/store/models';
import Problem from 'src/components/common/Problem.vue';
import { logger } from 'src/boot/logger';

interface SelectItem {
	label?: string;
	name?: string;
	crossref?: number;
	id: number;
}

interface LibraryProblem {
	id: number;
	source_code?: string;
	raw_source?: string;
	file_path?: string;
}

export default defineComponent({
	name: 'LibPanelOpl',
	components: {
		Problem
	},
	setup() {
		const store = useStore();
		const discipline: Ref<SelectItem|null>     = ref(null); // start with the select field to be empty.
		const subject: Ref<SelectItem|null>        = ref(null);
		const chapter: Ref<SelectItem|null>        = ref(null);
		const section: Ref<SelectItem|null>        = ref(null);
		const problems: Ref<Array<LibraryProblem>> = ref([]);

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
			problems,
			loadProblems: async () => {
				const sect = section.value;
				const response = await axios.get(`/opl/api/problems/sections/${sect?.id || 0}`);
				problems.value = response.data as Array<LibraryProblem>;
			},
			addProblem: async (problem: LibraryProblem) => {
				const set_id = store.state.app_state.library_state.target_set_id;
				const course_id = store.state.session.course.course_id;
				if (set_id > 0) {
					const url = `/courses/${course_id}/sets/${set_id}/problems`;
					await api.post(url, problem);
				}
				logger.debug(`[LibPanelOPL/addProblem] set_id: ${set_id}; adding: ${JSON.stringify(problem)}`);
			}
		};
	},
	async mounted() {
		const store = useStore();
		void store.dispatch('library/resetSections');
		void store.dispatch('library/resetChapters');
		void store.dispatch('library/resetSubjects');

		await store.dispatch('library/fetchDisciplines');
	}
});
</script>

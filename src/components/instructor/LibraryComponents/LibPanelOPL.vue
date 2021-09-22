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
	<div>
		<problem :raw_source="problems[0].raw_source" v-if="problems.length >0" />
	</div>
</template>

<script lang="ts">
import axios from 'axios';
import type { Ref } from 'vue';
import { defineComponent, ref, computed, watch } from 'vue';
import { useStore } from 'src/store';
import { Discipline, LibrarySubject } from 'src/store/models';
import Problem from 'src/components/common/Problem.vue';

interface SelectItem {
	label: string;
	id: number;
}

interface LibraryProblem {
	id: number;
	source_code: string;
	raw_source: string;

}

export default defineComponent({
	name: 'LibPanelOpl',
	components: {
		Problem
	},
	setup() {
		const store = useStore();
		const discipline = ref(null);
		const subject    = ref(null);
		const chapter    = ref(null);
		const section    = ref(null);
		const problems: Ref<Array<LibraryProblem>> = ref([]);

		watch([discipline], async () => {
			void store.dispatch('library/resetSections');
			void store.dispatch('library/resetChapters');
			void store.dispatch('library/resetSubjects');
			const d = discipline.value as unknown as SelectItem;
			await store.dispatch('library/fetchSubjects', { disc_id: d.id });
		});

		watch([subject], async () => {
			void store.dispatch('library/resetSections');
			void store.dispatch('library/resetChapters');
			const subj = subject.value as unknown as SelectItem;
			const d = discipline.value as unknown as SelectItem;
			await store.dispatch('library/fetchChapters', { disc_id: d.id, subj_id: subj.id });
		});

		watch([chapter], async () => {
			void store.dispatch('library/resetSections');
			const ch = chapter.value as unknown as SelectItem;
			const subj = subject.value as unknown as SelectItem;
			const d = discipline.value as unknown as SelectItem;
			await store.dispatch('library/fetchSections',
				{
					disc_id: d.id, subj_id: subj.id, chap_id: ch.id
				}
			);
		});

		return {
			discipline,
		  disciplines: computed(() =>
				store.state.library.disciplines.map(
					(obj: Discipline) => ({ label: obj.name, id: obj.id }))),
			subject,
			subjects: computed(() =>
				store.state.library.subjects.map(
					(obj: LibrarySubject) => ({ label: obj.name, id: obj.id })
				)),
			chapter,
			chapters: computed(() =>
				store.state.library.chapters.map(
					(obj: LibrarySubject) => ({ label: obj.name, id: obj.id })
				)),
			section,
			sections: computed(() =>
				store.state.library.sections.map(
					(obj: LibrarySubject) => ({ label: obj.name, id: obj.id })
				)),
			problems,
			loadProblems: async () => {
				const sect = section.value as unknown as SelectItem;
				const response = await axios.get(`/opl/api/problems/sections/${sect.id}`);
				problems.value = response.data as Array<LibraryProblem>;
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

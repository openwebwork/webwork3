<template>
	<h3>Student View for {{course_name}}</h3>
</template>

<script lang="ts">
import { defineComponent, computed, watch } from 'vue';

import { useStore } from '../../store';
export default defineComponent({
	name: 'Student',
	setup(props) {
		const store = useStore();
		console.log(props);
		watch( () => store.state.session.course_name, (state, prev_state) => {
			console.log(state);
			console.log(prev_state)
		});

		return {
			course_name: computed( () => store.state.session.course_name)
		};
	}
});
</script>
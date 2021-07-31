<template>
	<router-view />
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import { useStore } from '../../store';
export default defineComponent({
	name: 'Instructor',
	props: {
		course_name: String,
		course_id: String
	},
	setup (props){
		const store = useStore();
		console.log(props);
		if (props.course_id && props.course_name) {
			const course = {
				course_id: props.course_id,
				course_name: props.course_name
			};
			void store.dispatch('session/setCourse',course);
		}
	}
});
</script>
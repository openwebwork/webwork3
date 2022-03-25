// courses.spec.ts
// Test the Course Store

import { setActivePinia, createPinia } from 'pinia';
import { useCourseStore } from 'src/stores/courses';
import { createApp } from 'vue';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';

const app = createApp({});

describe('Set up the Course Store', () => {
	beforeEach(() => {
		// creates a fresh pinia and make it active so it's automatically picked
		// up by any useStore() call without having to pass it to it:
		// `useStore(pinia)`
		const pinia = createPinia().use(piniaPluginPersistedstate);
		app.use(pinia);
		setActivePinia(pinia);

		// setActivePinia(createPinia());
	});

	test('Fetch the courses', async () => {
		// The following is not working right now.
		const course_store = useCourseStore();

		await course_store.fetchCourses();

		expect(course_store.courses.length).toBeGreaterThan(0);

		expect(1).toBe(1);
	});
});

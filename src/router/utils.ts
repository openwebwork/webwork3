/**
 * This has some basic routing functions
 */

import { RouteLocationNormalizedLoaded } from 'vue-router';

export const parseRouteSetID = (route: RouteLocationNormalizedLoaded) => {
	return Array.isArray(route.params.set_id)
		? parseInt(route.params.set_id[0])
		: parseInt(route.params.set_id);
};

export const parseRouteCourseID = (route: RouteLocationNormalizedLoaded) => {
	return Array.isArray(route.params.course_id)
		? parseInt(route.params.course_id[0])
		: parseInt(route.params.course_id);
};

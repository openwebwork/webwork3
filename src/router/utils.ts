/**
 * This has some basic routing functions
 */

import { RouteLocationNormalizedLoaded } from 'vue-router';

export const parseRouteSetID = (route: RouteLocationNormalizedLoaded): number => {
	return Array.isArray(route.params.set_id)
		? parseInt(route.params.set_id[0])
		: parseInt(route.params.set_id);
};

export const parseRouteCourseID = (route: RouteLocationNormalizedLoaded): number => {
	return Array.isArray(route.params.course_id)
		? parseInt(route.params.course_id[0])
		: parseInt(route.params.course_id);
};

export const parseRouteUserID = (route: RouteLocationNormalizedLoaded): number => {
	return Array.isArray(route.params.user_id)
		? parseInt(route.params.user_id[0])
		: parseInt(route.params.user_id);
};

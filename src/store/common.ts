import { User, Course, CourseUser, ProblemSet, HomeworkSet, ProblemSetType,
	Quiz, QuizDates, QuizParams, ParseableProblemSet, CourseSetting,
	HomeworkSetParams, HomeworkSetDates } from './models';

import { cloneDeep } from 'lodash-es';

export function newUser(): User {
	return {
		email: '',
		first_name: '',
		is_admin: false,
		last_name: '',
		username: '',
		student_id: '',
		user_id: undefined
	};
}

export function newCourseUser(): CourseUser {
	return {
		course_user_id: 0,
		course_id: 0,
		role: 'student',
		section: '',
		recitation: '',
		params: {}
	};
}

export function newCourse(): Course {
	return {
		course_id: 0,
		course_name: '',
		visible: false,
		course_dates: {
			end: '',
			start: ''
		}
	};
}

export function newProblemSet(): ProblemSet {
	return {
		set_id: 0,
		set_name: '',
		course_id: 0,
		set_type: ProblemSetType.HW,
		set_visible: false,
		params: {},
		dates: {}
	};
}

export function copyProblemSet(target: ProblemSet, source: ProblemSet) {
	target.set_id = source.set_id;
	target.set_name = source.set_name;
	target.set_visible = source.set_visible;
	target.set_type = source.set_type;
	target.course_id = source.course_id;
	target.dates = cloneDeep(source.dates);
	target.params = cloneDeep(source.params);
}

export function parseHW(_set: ParseableProblemSet): HomeworkSet {

	const params: HomeworkSetParams = {};
	if (_set.params.enable_reduced_scoring !== undefined) {
		params.enable_reduced_scoring = parseInt(_set.params.enable_reduced_scoring)===1 ? true: false ;
	}
	if (_set.params.hide_hint !== undefined) {
		params.hide_hint = parseInt(_set.params.hide_hint)===1 ? true: false ;
	}
	if (_set.params.hardcopy_header !== undefined) {
		params.hardcopy_header = _set.params.hardcopy_header;
	}
	if (_set.params.set_header !== undefined) {
		params.set_header = _set.params.set_header;
	}
	if (_set.params.description !== undefined) {
		params.description = _set.params.description;
	}

	const dates: HomeworkSetDates = {
		open: parseInt(_set.dates.open),
		due: parseInt(_set.dates.due),
		answer: parseInt(_set.dates.answer)
	};
	if (_set.dates.reduced_scoring !== undefined){
		dates.reduced_scoring = parseInt(_set.dates.reduced_scoring);
	}

	return {
		set_id: parseInt(`${_set.set_id}`),
		set_name: _set.set_name,
		course_id: parseInt(`${_set.course_id}`),
		set_visible: 1 ? true : false,
		set_type: ProblemSetType.HW,
		params: params,
		dates: dates
	};
}

export function parseQuiz(_set: ParseableProblemSet): Quiz {

	const params: QuizParams = {
		timed: _set.params.timed === undefined ?
			undefined :
			parseInt(_set.params.timed)===1 ?
				true:
				false,
		time_length: _set.params.time_length === undefined ? undefined : parseInt(_set.params.time_length)
	};

	const dates: QuizDates = {
		open: parseInt(_set.dates.open),
		due: parseInt(_set.dates.due),
		answer: parseInt(_set.dates.answer)
	};

	return {
		set_id: parseInt(`${_set.set_id}`),
		set_name: _set.set_name,
		course_id: parseInt(`${_set.course_id}`),
		set_visible: 1 ? true : false,
		set_type: ProblemSetType.QUIZ,
		params: params,
		dates: dates
	};
}

export function newCourseSetting(): CourseSetting {
	return {
		var: '',
		value: ''
	};
}

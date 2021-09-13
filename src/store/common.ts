import { User, Course, CourseUser, ProblemSet, HomeworkSet, ProblemSetType,
	Quiz, QuizDates, QuizParams, ParseableProblemSet, CourseSetting,
	ReviewSet, ReviewSetParams, ReviewSetDates,
	HomeworkSetParams, HomeworkSetDates } from './models';

import { cloneDeep, pickBy } from 'lodash-es';

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

export function newHomeworkSet(): HomeworkSet {
	return {
		set_id: 0,
		set_name: '',
		course_id: 0,
		set_type: ProblemSetType.HW,
		set_visible: false,
		params: {},
		dates: {
			open: Date.now()/1000,
			due: Date.now()/1000,
			answer: Date.now()/1000
		}
	};
}

export function newQuiz(): Quiz {
	return {
		set_id: 0,
		set_name: '',
		course_id: 0,
		set_type: ProblemSetType.QUIZ,
		set_visible: false,
		params: {},
		dates: {
			open: Date.now()/1000,
			due: Date.now()/1000,
			answer: Date.now()/1000
		}
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

function parseBoolean(_value: boolean | string | number) {
	if (typeof _value === 'boolean') return _value;
	if (typeof _value === 'string' && !(/[01]/.exec(_value))) {
		return _value === 'true' || _value === 'false' ?
			_value === 'true' :
			undefined;
	} else {
		return _value === undefined ?
			undefined :
			parseInt(`${_value}`) === 1;
	}
}

export function parseHW(_set: ParseableProblemSet): HomeworkSet {

	const params: HomeworkSetParams = {
		enable_reduced_scoring: parseBoolean(_set.params.enable_reduced_scoring),
		hide_hint: parseBoolean(_set.params.hide_hint),
		hardcopy_header: _set.params.hardcopy_header,
		set_header: _set.params.set_header,
		description: _set.params.description
	};

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
		set_visible: parseBoolean(_set.set_visible) ?? false,
		set_type: ProblemSetType.HW,
		params: pickBy(params, (v) => v !== undefined),
		dates: dates
	};
}

export function parseQuiz(_set: ParseableProblemSet): Quiz {

	const params: QuizParams = {
		timed: parseBoolean(_set.params.timed),
		quiz_duration: _set.params.quiz_duration === undefined ? undefined : parseInt(_set.params.quiz_duration)
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
		set_visible: parseBoolean(_set.set_visible) ?? false,
		set_type: ProblemSetType.QUIZ,
		params: pickBy(params, (v) => v !== undefined),
		dates: dates
	};
}

export function parseReview(_set: ParseableProblemSet): ReviewSet {

	const params: ReviewSetParams = {
		allow: parseBoolean(_set.params.allow)
	};

	const dates: ReviewSetDates = {
		open: parseInt(_set.dates.open),
		closed: parseInt(_set.dates.closed)
	};

	return {
		set_id: parseInt(`${_set.set_id}`),
		set_name: _set.set_name,
		course_id: parseInt(`${_set.course_id}`),
		set_visible: parseBoolean(_set.set_visible) ?? false,
		set_type: ProblemSetType.REVIEW_SET,
		params: pickBy(params, (v) => v !== undefined),
		dates: dates
	};
}

export function newCourseSetting(): CourseSetting {
	return {
		var: '',
		value: ''
	};
}

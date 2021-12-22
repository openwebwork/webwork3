package DB::Exception;
use warnings;
use strict;

use Exception::Class (
	'DB::Exception::UndefinedCourseField' => {
		fields      => ['message'],
		description => 'There is an undefined course setting field'
	},
	'DB::Exception::InvalidCourseField' => {
		fields      => ['message'],
		description => 'There is an invalid parameter'
	},
	'DB::Exception::InvalidCourseFieldType' => {
		fields      => ['message'],
		description => 'There is an invalid field type'
	},
	'DB::Exception::UndefinedParameter' => {
		fields      => ['field_names'],
		description => 'There is an undefined parameter'
	},
	'DB::Exception::InvalidParameter' => {
		fields      => ['field_names'],
		description => 'There is an invalid parameter'
	},
	'DB::Exception::CourseNotFound' => {
		fields      => ['course_name'],
		description => 'The given course is not found.'
	},
	'DB::Exception::CourseExists' => {
		fields      => ['course_name'],
		description => 'The course already exists.'
	},
	'DB::Exception::UserNotFound' => {
		fields      => ['username'],
		description => 'The user was not found'
	},
	'DB::Exception::UserNotInCourse' => {
		fields      => [ 'username', 'course_name' ],
		description => 'The user is not a member of the course'
	},
	'DB::Exception::UserAlreadyInCourse' => {
		fields      => [ 'username', 'course_name' ],
		description => 'The user is already a member of the course'
	},
	'DB::Exception::UserExists' => {
		fields      => ['username'],
		description => 'The user already exists'
	},
	'DB::Exception::SetNotInCourse' => {
		fields      => [ 'set_name', 'course_name' ],
		description => 'The set is not in the course'
	},
	'DB::Exception::SetAlreadyExists' => {
		fields      => [ 'set_name', 'course_name' ],
		description => 'The set already exists in the course'
	},
	'DB::Exception::UserSetExists' => {
		fields      => [ 'set_name', 'course_name', "username" ],
		description => 'The user set already exists in the course'
	},
	'DB::Exception::UserSetNotInCourse' => {
		fields      => [ 'set_name', 'course_name', "username" ],
		description => 'The user set does not exist in the course'
	},
	'DB::Exception::ParametersNeeded' => {
		description => 'Parameters are needed that were not included.'
	},
	'DB::Exception::TooManyParameters' => {
		description => 'Too many parameters are passed in.'
	},
	'DB::Exception::InvalidDateField' => {
		fields      => ['field_names'],
		description => 'The date fields are invalid',
	},
	'DB::Exception::InvalidDateFormat' => {
		fields      => ['date'],
		description => 'The date format is invalid'
	},
	'DB::Exception::RequiredDateFields' => {
		fields      => ['field_names'],
		description => 'Missing required date fields'
	},
	'DB::Exception::ImproperDateOrder' => {
		fields      => ['field_names'],
		description => 'The dates are not in the proper order'
	},
	'DB::Exception::PoolNotInCourse' => {
		fields      => [ 'pool_name', 'course_name' ],
		description => 'The selected problem pool is not in the course'
	},
	'DB::Exception::PoolAlreadyInCourse' => {
		fields      => [ 'course_name', 'pool_name' ],
		description => 'The selected problem pool is already in the course'
	},
	'DB::Exception::PoolProblemNotInPool' => {
		fields      => ['info'],
		description => 'The requested problem is not in the selected problem pool'
	}
);

DB::Exception::UndefinedCourseField->Trace(1);
DB::Exception::InvalidCourseField->Trace(1);
DB::Exception::UserSetNotInCourse->Trace(1);
# DB::Exception::UserNotInCourse->Trace(1);
DB::Exception::UserNotFound->Trace(1);
DB::Exception::CourseExists->Trace(1);
DB::Exception::InvalidParameter->Trace(1);
DB::Exception::UndefinedParameter->Trace(1);
DB::Exception::InvalidDateField->Trace(1);
# DB::Exception::PoolNotInCourse->Trace(1);
DB::Exception::ParametersNeeded->Trace(1);
DB::Exception::UserSetExists->Trace(1);
DB::Exception::ImproperDateOrder->Trace(1);
1;

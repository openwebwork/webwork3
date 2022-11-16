#!/usr/bin/env perl

# This tests the basic database CRUD functions with courses.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Test::PostgreSQL;
use Mojo::JSON qw/true/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/dbSubtest/;

dbSubtest courses => sub ($schema) {
	my $course_rs = $schema->resultset('Course');

	# Add a course
	my $calc_course_params =
		{ course_name => 'Calculus', visible => true, course_dates => { start => '2020-09-01', end => '2020-12-16' } };
	my $calc_course    = $course_rs->addCourse(params => $calc_course_params);
	my $calc_course_id = $calc_course->{course_id};

	is(
		$calc_course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $calc_course_params->{course_name};
			field visible      => $calc_course_params->{visible};
			field course_dates => $calc_course_params->{course_dates};
			end;
		},
		'addCourse: add a new course'
	);

	# Add another course
	my $geometry_course_params = { course_name => 'Geometry', visible => true, course_dates => {} };
	my $geometry_course        = $course_rs->addCourse(params => $geometry_course_params);

	is(
		$geometry_course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $geometry_course_params->{course_name};
			field visible      => $geometry_course_params->{visible};
			field course_dates => $geometry_course_params->{course_dates};
			end;
		},
		'addCourse: add another new course'
	);

	# Retrive the list of all courses now in the database and check it is correct.
	my @courses_from_db = $course_rs->getCourses;
	@courses_from_db = sort { $a->{course_name} cmp $b->{course_name} } @courses_from_db;

	is(
		\@courses_from_db,
		array {
			item 0 => hash {
				field course_id    => match qr/^\d*$/;
				field course_name  => $calc_course_params->{course_name};
				field visible      => $calc_course_params->{visible};
				field course_dates => $calc_course_params->{course_dates};
				end;
			};
			item 1 => hash {
				field course_id    => match qr/^\d*$/;
				field course_name  => $geometry_course_params->{course_name};
				field visible      => $geometry_course_params->{visible};
				field course_dates => $geometry_course_params->{course_dates};
				end;
			};
			end;
		},
		'getCourses: get all courses'
	);

	# Get a single course by name
	my $course = $course_rs->getCourse(info => { course_name => 'Calculus' });

	is(
		$course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $calc_course_params->{course_name};
			field visible      => $calc_course_params->{visible};
			field course_dates => $calc_course_params->{course_dates};
			end;
		},
		'getCourse: get a single course by name'
	);

	# Get a single course by course_id
	$course = $course_rs->getCourse(info => { course_id => $calc_course_id });
	is(
		$course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $calc_course_params->{course_name};
			field visible      => $calc_course_params->{visible};
			field course_dates => $calc_course_params->{course_dates};
			end;
		},
		'getCourse: get a single course by id'
	);

	# Try to get a single course with invalid information.
	is(
		dies { $course_rs->getCourse(info => { course_id => $calc_course_id, course_name => 'Calculus' }); }
		,
		check_isa('DB::Exception::ParametersNeeded'),
		'getCourse: sends too much info'
	);

	is(
		dies { $course_rs->getCourse(info => { name => 'Calculus' }); },
		check_isa('DB::Exception::ParametersNeeded'),
		'getCourse: sends wrong info'
	);

	# Try to get a single course that doesn't exist
	is(
		dies { $course_rs->getCourse(info => { course_name => 'non_existent_course' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'getCourse: get a non-existent course'
	);

	# Add a course that already exists
	is(
		dies { $course_rs->addCourse(params => { course_name => 'Geometry', visible => true }); },
		check_isa('DB::Exception::CourseAlreadyExists'),
		'addCourse: course already exists'
	);

	# Update the course name
	my $updated_course = $course_rs->updateCourse(
		info   => { course_id   => $geometry_course->{course_id} },
		params => { course_name => 'Geometry II' }
	);

	$geometry_course_params->{course_name} = 'Geometry II';

	is(
		$updated_course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $geometry_course_params->{course_name};
			field visible      => $geometry_course_params->{visible};
			field course_dates => $geometry_course_params->{course_dates};
			end;
		},
		'updateCourse: update a course by name'
	);

	# Try to update an non-existent course
	is(
		dies { $course_rs->updateCourse(info => { course_name => 'non_existent_course' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'updateCourse: update a non-existent course_name'
	);

	is(
		dies { $course_rs->updateCourse(info => { course_id => -9 }, params => $geometry_course_params); },
		check_isa('DB::Exception::CourseNotFound'),
		'updateCourse: update a non-existent course_id'
	);

	# Delete a course
	my $deleted_course = $course_rs->deleteCourse(info => { course_name => 'Geometry II' });

	is(
		$deleted_course,
		hash {
			field course_id    => match qr/^\d*$/;
			field course_name  => $geometry_course_params->{course_name};
			field visible      => $geometry_course_params->{visible};
			field course_dates => $geometry_course_params->{course_dates};
			end;
		},
		'deleteCourse: delete a course'
	);

	# Try to delete a non-existent course by name
	is(
		dies { $course_rs->deleteCourse(info => { course_name => 'undefined_name' }) },
		check_isa('DB::Exception::CourseNotFound'),
		'deleteCourse: delete a non-existent course_name'
	);

	# Try to delete a non-existent course by id
	is(
		dies { $course_rs->deleteCourse(info => { course_id => -9 }) },
		check_isa('DB::Exception::CourseNotFound'),
		'deleteCourse: delete a non-existent course_id'
	);
};

done_testing();

#
# This tests the basic database CRUD functions with courses.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use lib "$main::lib_dir";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use List::MoreUtils qw(uniq);

use Test::More;
use Test::Exception;
use Try::Tiny;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my $course_rs = $schema->resultset("Course");

## get a list of courses from the CSV file

my $students      = csv( in => "$main::test_dir/sample_data/students.csv", headers => "lc" );
my @known_courses = uniq map { $_->{course_name}; } @$students;
@known_courses = map { { course_name => $_ }; } ( sort @known_courses );

## check the list of all courses
my @courses_from_db   = $course_rs->getCourses;
my $course_rs_from_db = sortByCourseName( removeCourseID( \@courses_from_db ) );
is_deeply( $course_rs_from_db, \@known_courses, "getCourses: course names" );

## get a single course by name

my $course  = $course_rs->getCourse( { course_name => "Calculus" } );
my $calc_id = $course->{course_id};
delete $course->{course_id};
is_deeply( $course, { course_name => "Calculus" }, "getCourse: get a single course by name" );

## get a single course by course_id

$course = $course_rs->getCourse( { course_id => $calc_id } );
delete $course->{course_id};
is_deeply( $course, { course_name => "Calculus" }, "getCourse: get a single course by id" );

## try to get a single course with sending proper info:
throws_ok {
	$course_rs->getCourse( { course_id => $calc_id, course_name => "Calculus" } );
} "DB::Exception::ParametersNeeded", "getCourse: sends too much info";

throws_ok {
	$course_rs->getCourse( { name => "Calculus" } );
} "DB::Exception::ParametersNeeded", "getCourse: sends wrong info";

## try to get a single course that doesn't exist

throws_ok {
	$course_rs->getCourse( { course_name => "non_existent_course" } );
} "DB::Exception::CourseNotFound", "getCourse: get a non-existent course";

## add a course
my $new_course = $course_rs->addCourse("Geometry");
push( @known_courses, { course_name => $new_course->{course_name} } );
my $known_courses = sortByCourseName( \@known_courses );

@courses_from_db   = $course_rs->getCourses;
$course_rs_from_db = sortByCourseName( removeCourseID( \@courses_from_db ) );

is_deeply( $known_courses, $course_rs_from_db, "addCourse: add a new course" );

## add a course that already exists

throws_ok {
	$course_rs->addCourse("Geometry");
} "DB::Exception::CourseExists", "addCourse: course already exists";

## update a course

my $new_course_params = { course_name => "Geometry II" };
my $updated_course    = $course_rs->updateCourse( { course_name => "Geometry" }, $new_course_params );
my $new_course_id     = $updated_course->{course_id};
delete $updated_course->{course_id};

is_deeply( $new_course_params, $updated_course, "updateCourse: update a course by name" );

## Try to update an non-existent course

throws_ok {
	$course_rs->updateCourse( { course_name => "non_existent_course" } );
} "DB::Exception::CourseNotFound", "updateCourse: update a non-existent course_name";

throws_ok {
	$course_rs->updateCourse( { course_id => -9 }, $new_course_params );
} "DB::Exception::CourseNotFound", "updateCourse: update a non-existent course_id";

## delete a course
my $deleted_course = $course_rs->deleteCourse( { course_name => "Geometry II" } );
@known_courses = grep { $_->{course_name} ne "Geometry" } @known_courses;
$known_courses = sortByCourseName( \@known_courses );

@courses_from_db   = $course_rs->getCourses;
$course_rs_from_db = sortByCourseName( removeCourseID( \@courses_from_db ) );
is_deeply( $course_rs_from_db, \@known_courses, "deleteCourse: delete a course" );

## try to delete a non-existent course by name
throws_ok {
	$course_rs->deleteCourse( { course_name => "undefined_name" } )
} "DB::Exception::CourseNotFound", "deleteCourse: delete a non-existent course_name";

## try to delete a non-existent course by id
throws_ok {
	$course_rs->deleteCourse( { course_id => -9 } )
} "DB::Exception::CourseNotFound", "deleteCourse: delete a non-existent course_id";

sub sortByCourseName {
	my $course_rs = shift;
	my @new_array = sort { $a->{course_name} cmp $b->{course_name} } @$course_rs;
	return \@new_array;
}

sub removeCourseID {
	my $course_rs = shift;
	for my $course (@$course_rs) {
		delete $course->{course_id};
	}
	return $course_rs;
}

done_testing();


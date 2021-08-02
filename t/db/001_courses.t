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

use Data::Dump qw/dd/;
use List::MoreUtils qw(uniq);

use Test::More;
use Test::Exception;
use Try::Tiny;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;

use DB::TestUtils qw/loadCSV removeIDs/;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my $course_rs = $schema->resultset("Course");

## get a list of courses from the CSV file

my @courses = loadCSV("$main::test_dir/sample_data/courses.csv");
for my $course (@courses) {

	# my $course_settings = {
	# 	general => {},
	# 	optional => {},
	# 	problem_set => {},
	# 	problem => {},
	# 	permissions => {},
	# 	email => {}
	# };
	# for my $key (keys %{$course->{params}}) {
	# 	my @fields = split(/:/,$key);
	# 	$course_settings->{$fields[0]}->{$fields[1]} = $course->{params}->{$key};
	# }
	# $course->{course_settings} = $course_settings;
	# $course->{course_params} = $course->{params};
	delete $course->{params};
	$course->{course_dates} = $course->{dates};
	delete $course->{dates};
}
@courses = sortByCourseName( \@courses );

## check the list of all courses
my @courses_from_db = $course_rs->getCourses;
for my $course (@courses_from_db) { removeIDs($course); }
@courses_from_db = sortByCourseName( \@courses_from_db );

is_deeply( \@courses_from_db, \@courses, "getCourses: course names" );

## get a single course by name

my $course  = $course_rs->getCourse( { course_name => "Calculus" } );
my $calc_id = $course->{course_id};
delete $course->{course_id};
my @calc_courses = grep { $_->{course_name} eq "Calculus" } @courses;
is_deeply( $course, $calc_courses[0], "getCourse: get a single course by name" );

## get a single course by course_id

$course = $course_rs->getCourse( { course_id => $calc_id } );
delete $course->{course_id};
is_deeply( $course, $calc_courses[0], "getCourse: get a single course by id" );

## try to get a single course with sending proper info:
throws_ok {
	$course_rs->getCourse( { course_id => $calc_id, course_name => "Calculus" } );
}
"DB::Exception::ParametersNeeded", "getCourse: sends too much info";

throws_ok {
	$course_rs->getCourse( { name => "Calculus" } );
}
"DB::Exception::ParametersNeeded", "getCourse: sends wrong info";

## try to get a single course that doesn't exist

throws_ok {
	$course_rs->getCourse( { course_name => "non_existent_course" } );
}
"DB::Exception::CourseNotFound", "getCourse: get a non-existent course";

## add a course
my $new_course_params = {
	course_name  => "Geometry",
	visible      => 1,
	course_dates => {}
};

my $new_course      = $course_rs->addCourse($new_course_params);
my $added_course_id = $new_course->{course_id};
removeIDs($new_course);

is_deeply( $new_course_params, $new_course, "addCourse: add a new course" );

## add a course that already exists

throws_ok {
	$course_rs->addCourse( { course_name => "Geometry", visible => 1 } );
}
"DB::Exception::CourseExists", "addCourse: course already exists";

## update the course name

my $updated_course = $course_rs->updateCourse( { course_id => $added_course_id }, { course_name => "Geometry II" } );

$new_course_params->{course_name} = "Geometry II";
delete $updated_course->{course_id};

is_deeply( $new_course_params, $updated_course, "updateCourse: update a course by name" );

## Try to update an non-existent course

throws_ok {
	$course_rs->updateCourse( { course_name => "non_existent_course" } );
}
"DB::Exception::CourseNotFound", "updateCourse: update a non-existent course_name";

throws_ok {
	$course_rs->updateCourse( { course_id => -9 }, $new_course_params );
}
"DB::Exception::CourseNotFound", "updateCourse: update a non-existent course_id";

## delete a course
my $deleted_course = $course_rs->deleteCourse( { course_name => "Geometry II" } );
removeIDs($deleted_course);

is_deeply( $new_course_params, $deleted_course, "deleteCourse: delete a course" );

## try to delete a non-existent course by name
throws_ok {
	$course_rs->deleteCourse( { course_name => "undefined_name" } )
}
"DB::Exception::CourseNotFound", "deleteCourse: delete a non-existent course_name";

## try to delete a non-existent course by id
throws_ok {
	$course_rs->deleteCourse( { course_id => -9 } )
}
"DB::Exception::CourseNotFound", "deleteCourse: delete a non-existent course_id";

## get a list of courses for a user

my @user_courses = $course_rs->getUserCourses( { login => "lisa" } );
for my $user_course (@user_courses) {
	removeIDs($user_course);
}

my @students = loadCSV("$main::test_dir/sample_data/students.csv");

my @user_courses_from_csv = grep { $_->{login} eq "lisa" } @students;

for my $user_course (@user_courses_from_csv) {
	for my $key (qw/email first_name last_name login student_id/) {
		delete $user_course->{$key};
	}
}

is_deeply( \@user_courses, \@user_courses_from_csv, "getUserCourses: get all courses for a given user" );

## try to get a list of course from a non-existent user

throws_ok {
	$course_rs->getUserCourses( { login => "non_existent_user" } );
}
"DB::Exception::UserNotFound", "getUserCourse: try to get a list of courses for a non-existent user";

sub sortByCourseName {
	my $course_rs = shift;
	my @new_array = sort { $a->{course_name} cmp $b->{course_name} } @$course_rs;
	return @new_array;
}

done_testing();


#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions("perm" => \$TEST_PERMISSIONS);

use Clone qw/clone/;
use YAML::XS qw/LoadFile/;

# Test the api with common "courses" routes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

my $t;

if ($TEST_PERMISSIONS) {
	$config->{ignore_permissions} = 0;
	$t = Test::Mojo->new(WeBWorK3 => $config);

	$t->post_ok('/api/login' => json => { email => 'admin@google.com', password => 'admin' })
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)->json_is('/user/user_id' => 1)
		->json_is('/user/is_admin' => 1);

} else {
	$config->{ignore_permissions} = 1;
	$t = Test::Mojo->new(WeBWorK3 => $config);
}

$t->get_ok('/webwork3/api/courses')->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/course_name' => "Precalculus")->json_is('/0/visible' => 1);

$t->get_ok('/webwork3/api/courses/1')->content_type_is('application/json;charset=UTF-8')
	->json_is('/course_name' => "Precalculus")->json_is('/visible' => 1);

# Add a new course
my $new_course = {
	course_name  => "Linear Algebra",
	course_dates => { start => "2021-05-31", end => "2021-07-01" }
};

$t->post_ok('/webwork3/api/courses' => json => $new_course)->status_is(200)
	->json_is('/course_name' => $new_course->{course_name});

# Extract the id from the response.
my $new_course_id = $t->tx->res->json('/course_id');
$new_course->{course_id} = $new_course_id;
is_deeply($new_course, $t->tx->res->json, "addCourse: courses match");

# Update the course
$new_course->{visible} = 0;
$t->put_ok("/webwork3/api/courses/$new_course_id" => json => $new_course)->status_is(200)
	->json_is('/course_name' => $new_course->{course_name});

is_deeply($new_course, $t->tx->res->json, "updateCourse: courses match");

# Test for exceptions

# A set that is not in a course.
$t->get_ok("/webwork3/api/courses/99999")->status_is(250, 'error status')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::CourseNotFound');

# Try to update a non-existent course
$t->put_ok("/webwork3/api/courses/999999" => json => { course_name => 'new course name' })
	->status_is(250, 'error status')->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::CourseNotFound');

# Try to add a course without a course_name.
my $another_new_course = { name => "this is the wrong field" };

$t->post_ok("/webwork3/api/courses/" => json => $another_new_course)->status_is(250, 'error status')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# Try to delete a non-existent course.
$t->delete_ok("/webwork3/api/courses/9999999")->status_is(250, 'error status')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::CourseNotFound');

# Delete the added course.
$t->delete_ok("/webwork3/api/courses/$new_course_id")->status_is(200)
	->json_is('/course_name' => $new_course->{course_name});

if ($TEST_PERMISSIONS) {
	# Login a non admin user
	$t->post_ok('/webwork3/api/login' => json => { email => 'lisa@google.com', password => 'lisa' })
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)
		->json_is('/user/login' => "lisa")->json_is('/user/is_admin' => 0);

	$t->get_ok('/webwork3/api/courses')->content_type_is('application/json;charset=UTF-8')
		->json_is('/0/course_name' => "Precalculus")->json_is('/0/course_params/institution' => "Springfield CC");

	$t->get_ok('/webwork3/api/courses/1')->content_type_is('application/json;charset=UTF-8')
		->json_is('/course_name' => "Precalculus")->json_is('/course_params/institution' => "Springfield CC");

	# The following shouldn't have permissions for these routes.

	$t->post_ok('/webwork3/api/courses' => json => $new_course)->status_is(200)->json_is('/has_permission' => 0);

	$t->put_ok("/webwork3/api/courses/1" => json => { course_name => "XXX" })->status_is(200)
		->json_is('/has_permission' => 0);

	$t->delete_ok("/webwork3/api/courses/1")->status_is(200)->json_is('/has_permission' => 0);
}

done_testing;

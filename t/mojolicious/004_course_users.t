#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON qw/true false/;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use DB::Schema;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;

# Test the api with common 'courses/users' routes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

# Connect to the database.
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $t = Test::Mojo->new(WeBWorK3 => $config);

$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)->json_is('/user/user_id' => 1)
	->json_is('/user/is_admin' => 1);

# Get all users for use below
$t->get_ok('/webwork3/api/users')->status_is(200)->content_type_is('application/json;charset=UTF-8');
my $all_users = $t->tx->res->json;

$t->get_ok('/webwork3/api/courses/4/users')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/role' => 'INSTRUCTOR')->json_is('/1/role' => 'STUDENT');

# Extract id from the response.
my $user_id = $t->tx->res->json('/0/user_id');

$t->get_ok("/webwork3/api/courses/2/users/$user_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/user_id' => $user_id)->json_is('/role' => 'STUDENT');

# Add a new global user.
my $new_user = {
	email      => 'maggie@abc.com',
	first_name => 'Maggie',
	last_name  => 'Simpson',
	username   => 'maggie',
	student_id => '1234123423'
};
$t->post_ok('/webwork3/api/users' => json => $new_user)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/first_name' => $new_user->{first_name})
	->json_is('/email' => $new_user->{email});

# Add the user to a course.
my $new_user_id        = $t->tx->res->json('/user_id');
my $course_user_params = {
	user_id            => $new_user_id,
	role               => 'STUDENT',
	course_user_params => {
		comment => 'I love my big sister'
	}
};

$t->post_ok('/webwork3/api/courses/2/users' => json => $course_user_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/role' => $course_user_params->{role})
	->json_is('/course_user_params/comment' => $course_user_params->{course_user_params}->{comment});

# Update the new user.
$new_user->{recitation} = 2;
$t->put_ok("/webwork3/api/courses/2/users/$new_user_id" => json => { recitation => 2 })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/recitation' => 2);

# Test for exceptions

# A non-existent user
$t->get_ok('/webwork3/api/courses/1/users/99999')->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# Check that a new user is not in a course.
$t->get_ok("/webwork3/api/courses/1/users/$new_user_id")->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to update a user that is not in a course.
$t->put_ok("/webwork3/api/courses/1/users/$new_user_id" => json => { recitation => '2' })
	->status_is(500, 'status for exception')->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to add a user without a username.
$t->post_ok('/webwork3/api/courses/1/users' => json => { username_name => 'this is the wrong field' })
	->status_is(500, 'status for exception')->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# Try to delete a user that is not found.
$t->delete_ok('/webwork3/api/courses/1/users/99')->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# Try to delete a user that is not in a course.
$t->delete_ok("/webwork3/api/courses/1/users/$new_user_id")->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

$t->delete_ok("/webwork3/api/courses/2/users/$new_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $new_user_id);

# Logout of the admin user account.
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => 0);

# Login as a non-admin
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Lisa has instructor access in the Arithmetic Course (course_id => 4)
$t->get_ok('/webwork3/api/courses/4/users')->status_is(200)->content_type_is('application/json;charset=UTF-8');
use Data::Dumper;

my $course4_users = $t->tx->res->json;
# get the user_id of a student
my $course4_student_user_id = $course4_users->[1]->{user_id};
$t->get_ok("/webwork3/api/courses/4/users/$course4_student_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/username' => $course4_users->[1]->{username});

# add Maggie to the course
my $maggie = $schema->resultset('User')->find({ username => 'maggie' });

$t->post_ok(
	'/webwork3/api/courses/4/users' => json => {
		user_id => $maggie->user_id,
		role    => 'STUDENT'
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $maggie->user_id)
	->json_is('/role' => 'STUDENT');

$t->put_ok(
	'/webwork3/api/courses/4/users/'
		. $maggie->user_id => json => {
			recitation => 4
		}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/recitation' => 4);

$t->delete_ok('/webwork3/api/courses/4/users/' . $maggie->user_id)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $maggie->user_id)
	->json_is('/role' => 'STUDENT');

# Check that a student doesn't have the same access as an instructor
# The user lisa is a student in the 'Topology' course (course_id => 3)
# This checks that she doesn't have the instructor access to this course.
$t->get_ok('/webwork3/api/courses/3/users')->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->post_ok(
	'/webwork3/api/courses/3/users' => json => {
		user_id => $maggie->user_id,
		role    => 'STUDENT'
	}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->put_ok(
	'/webwork3/api/courses/3/users/'
		. $maggie->user_id => json => {
			recitation => 4
		}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->delete_ok('/webwork3/api/courses/3/users/' . $maggie->user_id)->status_is(403)
	->content_type_is('application/json;charset=UTF-8');

# Remove the user 'maggie' that was added.
if (defined($maggie)) {
	my $maggie_cu = $schema->resultset('CourseUser')->search({ user_id => $maggie->user_id });
	$maggie_cu->delete_all if defined($maggie_cu);
	$maggie->delete        if defined($maggie);
}

done_testing;

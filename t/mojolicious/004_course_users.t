#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Data::Dumper;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path(dirname(__FILE__));
	$main::lib_dir  = dirname(dirname($main::test_dir)) . '/lib';
}

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions("perm" => \$TEST_PERMISSIONS);    # check for the flag --perm when running this.

use lib "$main::lib_dir";
use DB::Schema;
use DB::TestUtils qw/loadSchema/;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;

my $config = clone(LoadFile("$main::lib_dir/../conf/webwork3.yml"));

# Test the api with common "courses" routes

my $schema = loadSchema();

my $t;

if ($TEST_PERMISSIONS) {
	$config->{ignore_permissions} = 0;
	$t = Test::Mojo->new(WeBWorK3 => $config);

	# username an admin
	$t->post_ok('/webwork3/api/username' => json => { email => 'admin@google.com', password => 'admin' })
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)
		->json_is('/user/user_id' => 1)->json_is('/user/is_admin' => 1);

} else {
	$config->{ignore_permissions} = 1;
	$t = Test::Mojo->new(WeBWorK3 => $config);
}

# remove the maggie user if exists in the database
my $maggie = $schema->resultset("User")->find({ username => "maggie" });
if (defined($maggie)) {
	my $maggie_cu = $schema->resultset("CourseUser")->search({ user_id => $maggie->user_id });
	$maggie_cu->delete_all if defined($maggie_cu);
	$maggie->delete        if defined($maggie);
}

$t->get_ok('/webwork3/api/courses/4/users')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/role' => "instructor")->json_is('/1/role' => 'student');

print Dumper($t->tx->res->json);

# Pull out the id from the response
my $user_id = $t->tx->res->json('/0/user_id');

$t->get_ok("/webwork3/api/courses/2/users/$user_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/user_id' => $user_id)->json_is('/role' => "student");

## add a new global user

my $new_user = {
	email      => 'maggie@abc.com',
	first_name => "Maggie",
	last_name  => "Simpson",
	username   => "maggie",
	student_id => "1234123423"
};

$t->post_ok("/webwork3/api/users" => json => $new_user)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/first_name' => $new_user->{first_name})
	->json_is('/email' => $new_user->{email});

# then add the user to a course

my $new_user_id = $t->tx->res->json('/user_id');

my $course_user_params = {
	user_id => $new_user_id,
	role    => "student",
	params  => {
		comment => "I love my big sister"
	}
};

$t->post_ok("/webwork3/api/courses/2/users" => json => $course_user_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/role' => $course_user_params->{role})
	->json_is('/params/comment' => $course_user_params->{params}->{comment});

# update the new user

$new_user->{recitation} = 2;
$t->put_ok("/webwork3/api/courses/2/users/$new_user_id" => json => { recitation => 2 })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/recitation' => 2);

## test for exceptions

# a non-existent user
$t->get_ok("/webwork3/api/courses/1/users/99999")->status_is(250, "status for exception")
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# check that a new is not in a course
$t->get_ok("/webwork3/api/courses/1/users/$new_user_id")->status_is(250, "status for exception")
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# try to update a user not in a course

$t->put_ok("/webwork3/api/courses/1/users/$new_user_id" => json => { recitation => '2' })
	->status_is(250, "status for exception")->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# try to add a user without a username

my $another_new_user = { username_name => "this is the wrong field" };

$t->post_ok("/webwork3/api/courses/1/users" => json => $another_new_user)->status_is(250, "status for exception")
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# try to delete a user not found
$t->delete_ok("/webwork3/api/courses/1/users/99")->status_is(250, "status for exception")
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# try to delete a user not in a course
$t->delete_ok("/webwork3/api/courses/1/users/$new_user_id")->status_is(250, "status for exception")
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

$t->delete_ok("/webwork3/api/courses/2/users/$new_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $new_user_id);

if ($TEST_PERMISSIONS) {
	$t->post_ok("/webwork3/api/logout")->status_is(200)->json_is('/logged_in' => 0);
}

## check that a non_admin user has proper access.

my @all_users   = $schema->resultset("User")->getCourseUsers({ course_id => 1 });
my @instructors = grep { $_->{role} eq 'instructor' } @all_users;

if ($TEST_PERMISSIONS) {
	$t->post_ok(
		"/webwork3/api/username" => json => {
			email    => $instructors[0]->{email},
			password => $instructors[0]->{username}
		}
	)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1);

	$t->get_ok('/webwork3/api/courses/1/users')->status_is(200)->content_type_is('application/json;charset=UTF-8');

}

done_testing;

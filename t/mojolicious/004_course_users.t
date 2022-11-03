#!/usr/bin/env perl

use Mojo::Base -strict;

use Test2::V0;
use Test2::MojoX;
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
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

my $t = Test2::MojoX->new(WeBWorK3 => $config);

# Login as an instructor in the Arithmetic course (course_id: 4)
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Get all course users in course_id: 4
$t->get_ok('/webwork3/api/courses/4/global-courseusers')->status_is(200)
	->content_type_is('application/json;charset=UTF-8');
my $all_users = $t->tx->res->json;

$t->get_ok('/webwork3/api/courses/4/users')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/role' => 'instructor')->json_is('/1/role' => 'student');

# Extract id from the response.
my $user_id = $t->tx->res->json('/1/user_id');

$t->get_ok("/webwork3/api/courses/4/users/$user_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/user_id' => $user_id)->json_is('/role' => 'student');

# Add a new global user.
my $new_user = {
	email      => 'maggie@abc.com',
	first_name => 'Maggie',
	last_name  => 'Simpson',
	username   => 'maggie',
	student_id => '1234123423'
};
$t->post_ok('/webwork3/api/courses/4/global-users' => json => $new_user)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/first_name' => $new_user->{first_name})
	->json_is('/email' => $new_user->{email});

# Add the user to a course.
my $new_user_id        = $t->tx->res->json('/user_id');
my $course_user_params = {
	user_id            => $new_user_id,
	role               => 'student',
	course_user_params => {
		comment      => "I love my big sister",
		useMathQuill => true
	}
};

$t->post_ok('/webwork3/api/courses/4/users' => json => $course_user_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/role' => $course_user_params->{role})
	->json_is('/course_user_params/comment' => $course_user_params->{course_user_params}->{comment});

my $added_user = $t->tx->res->json;

# Update the new user.
$new_user->{recitation} = 2;
$t->put_ok("/webwork3/api/courses/4/users/$new_user_id" => json => { recitation => 2 })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/recitation' => 2);

# Test that the booleans are being sent as JSON booleans:
ok($added_user->{course_user_params}->{useMathQuill}, 'Testing that useMathQuill param is truthy.');
is($added_user->{course_user_params}->{useMathQuill},
	true, 'Testing that the useMathQuill param compares to JSON::true');
ok(
	JSON::PP::is_bool($added_user->{course_user_params}->{useMathQuill}),
	'Testing that the useMathQuill param is a JSON boolean'
);
ok(
	JSON::PP::is_bool($added_user->{course_user_params}->{useMathQuill})
		&& $added_user->{course_user_params}->{useMathQuill},
	'testing that the useMathQuill param is a JSON::true'
);

# Test for exceptions

# A non-existent user
$t->get_ok('/webwork3/api/courses/4/users/99999')->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# Check that a new user is not in a course.
$t->get_ok("/webwork3/api/courses/4/users/5")->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to update a user that is not in a course.
$t->put_ok("/webwork3/api/courses/4/users/5" => json => { recitation => '2' })->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to add a user without a username.
$t->post_ok('/webwork3/api/courses/4/users' => json => { username_name => 'this is the wrong field' })
	->status_is(500, 'status for exception')->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# Try to delete a user that is not found.
$t->delete_ok('/webwork3/api/courses/4/users/99')->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotFound');

# Try to delete a user that is not in a course.
$t->delete_ok("/webwork3/api/courses/4/users/5")->status_is(500, 'status for exception')
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Delete the added course user
$t->delete_ok("/webwork3/api/courses/4/users/$new_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $new_user_id);

# Check that a student doesn't have the same access as an instructor
# The user lisa is a student in the 'Topology' course (course_id => 3)
# This checks that she doesn't have the instructor access to this course.
$t->get_ok('/webwork3/api/courses/3/users')->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->post_ok(
	'/webwork3/api/courses/3/users' => json => {
		user_id => $new_user_id,
		role    => 'student'
	}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->put_ok(
	'/webwork3/api/courses/3/users/'
		. $new_user_id => json => {
			recitation => 4
		}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->delete_ok('/webwork3/api/courses/3/users/' . $new_user_id)->status_is(403)
	->content_type_is('application/json;charset=UTF-8');

# Delete the added global user, but need to relogin as admin
$t->post_ok('/webwork3/api/logout')->status_is(200);
$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200);

# Delete the added users.
$t->delete_ok("/webwork3/api/users/$new_user_id")->status_is(200)->json_is('/username' => $new_user->{username});

done_testing;

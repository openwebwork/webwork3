#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON;

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

$t->get_ok('/webwork3/api/courses/4/users')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/0/role' => 'instructor')->json_is('/1/role' => 'student');

# Extract id from the response.
my $user_id = $t->tx->res->json('/0/user_id');

$t->get_ok("/webwork3/api/courses/2/users/$user_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/user_id' => $user_id)->json_is('/role' => 'student');

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
	role               => 'student',
	course_user_params => {
		comment      => "I love my big sister",
		useMathQuill => Mojo::JSON::true
	}
};

$t->post_ok('/webwork3/api/courses/2/users' => json => $course_user_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/role' => $course_user_params->{role})
	->json_is('/course_user_params/comment' => $course_user_params->{course_user_params}->{comment});

my $added_user = $t->tx->res->json;

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

# Delete the added course user
$t->delete_ok("/webwork3/api/courses/2/users/$new_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $new_user_id);

# Delete the added global user
$t->delete_ok("/webwork3/api/users/$new_user_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/user_id' => $new_user_id);

# Logout of the admin user account.
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => 0);

# Check that a non_admin user has proper access.
my @instructors =
	grep { $_->{role} eq 'instructor' } $schema->resultset('User')->getCourseUsers(info => { course_id => 1 });
my $instructor = $schema->resultset('User')->getGlobalUser(info => { user_id => $instructors[0]{user_id} });

$t->post_ok(
	'/webwork3/api/login' => json => { username => $instructor->{username}, password => $instructor->{username} })
	->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1);

$t->get_ok('/webwork3/api/courses/1/users')->status_is(200)->content_type_is('application/json;charset=UTF-8');

# Test that boolean fields inside of course_user_params are JSON true/false.

ok($added_user->{course_user_params}->{useMathQuill}, 'Testing that useMathQuill param is truthy.');
is($added_user->{course_user_params}->{useMathQuill},
	Mojo::JSON::true, 'Testing that the useMathQuill param compares to JSON::true');
ok(
	JSON::PP::is_bool($added_user->{course_user_params}->{useMathQuill}),
	'Testing that the useMathQuill param is a JSON boolean'
);
ok(
	JSON::PP::is_bool($added_user->{course_user_params}->{useMathQuill})
		&& $added_user->{course_user_params}->{useMathQuill},
	'testing that the useMathQuill param is a JSON::true'
);

done_testing;

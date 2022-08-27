#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON qw/true false/;

use DateTime::Format::Strptime;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use DB::Schema;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
use TestUtils qw/loadCSV removeIDs cleanUndef/;

# Tests the versioning of user sets.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);
my $t = Test::Mojo->new(WeBWorK3 => $config);

# Login as an instructor.  frink is an instructor in course_id: 1 (Precalculus)
$t->post_ok('/webwork3/api/login' => json => { username => 'frink', password => 'frink' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'frink')->json_is('/user/is_admin' => false);

# Get all problem sets for the Precalc course (course_id: 1)
$t->get_ok('/webwork3/api/courses/1/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');
my $precalc_sets = $t->tx->res->json;

# Need to fetch the problem set for HW #1 for the set_id
my $hw1 = (grep { $_->{set_name} eq 'HW #1' } @$precalc_sets)[0];

# need the user_id of a user.
$t->get_ok('/webwork3/api/courses/1/global-courseusers')->status_is(200);
my $course_users = $t->tx->res->json;

my $otto_user = (grep { $_->{username} eq 'otto' } @$course_users)[0];

# Add a default user_set

my $user_set_params = {
	user_id    => $otto_user->{user_id},
	set_dates  => { due => $hw1->{set_dates}{due} + 200 },
	set_params => {}
};

$t->post_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users" => json => $user_set_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_set_v0 = $t->tx->res->json;

# Check that the route without a set_version is the same as this.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_set_v0a = $t->tx->res->json;
cleanUndef($user_set_v0a);

is_deeply($user_set_v0a, $user_set_v0, 'user set with version: check the default version.');

# Check that a get specifying a set_version works the same
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/0")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_set_v0b = $t->tx->res->json;
cleanUndef($user_set_v0b);

is_deeply($user_set_v0b, $user_set_v0, 'user set with version: check v/0 route returns the default version.');

# Add another set_version

my $user_set_params2 = {
	user_id     => $otto_user->{user_id},
	set_dates   => { answer => $hw1->{set_dates}{due} + 400 },
	set_params  => {},
	set_version => 1
};

$t->post_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users" => json => $user_set_params2)->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_set_v1 = $t->tx->res->json;

# Check that the route without a set_version is the same as this.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/1")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_set_v1a = $t->tx->res->json;
cleanUndef($user_set_v1a);

is_deeply($user_set_v1a, $user_set_v1, 'user set with set_version of 1');

# Update the user set

$user_set_params2->{set_params}->{description} = 'This is user_set v1';

$t->put_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/1" => json => $user_set_params2)
	->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_params/description' => 'This is user_set v1');

# Test for exceptions

# Try to get a non-existent set version
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/99")->status_is(500)
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

# Try to update a non-existent set version
$t->put_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/99" => json =>
		{ set_visible => false })->status_is(500)->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

# Try to delete a non-existent set version
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/99")->status_is(500)
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

# Some cleanup to restore the database
# Delete a user set of version 1
$t->delete_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/1")
	->content_type_is('application/json;charset=UTF-8')->status_is(200);

# And check that the problem set is no longer in the db.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/1")->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

# Delete a user set of version 0
$t->delete_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/0")
	->content_type_is('application/json;charset=UTF-8')->status_is(200);

# And check that the problem set is no longer in the db.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}/v/0")->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

done_testing;

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

# Test the api with user set routes.

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

# Load info from CSV files
my @hw_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/hw_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}   = "HW";
	$hw_set->{set_params} = {} unless defined $hw_set->{set_params};
}

my @quizzes = loadCSV(
	"$main::ww3_dir/t/db/sample_data/quizzes.csv",
	{
		boolean_fields           => ['set_visible'],
		param_boolean_fields     => ['timed'],
		param_non_neg_int_fields => ['quiz_duration']
	}
);
for my $set (@quizzes) {
	$set->{set_type}   = "QUIZ";
	$set->{set_params} = {} unless defined $set->{set_params};
}

my @review_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/review_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => ['can_retake']
	}
);

for my $set (@review_sets) {
	$set->{set_type}   = "REVIEW";
	$set->{set_params} = {} unless defined $set->{set_params};
}

my @all_problem_sets = (@hw_sets, @quizzes, @review_sets);

my @all_user_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/user_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);

for my $set (@all_user_sets) {
	$set->{set_version} = 0 unless defined($set->{set_version});
	# find the problem set type
	my $s =
		(grep { $_->{course_name} eq $set->{course_name} && $_->{set_name} eq $set->{set_name} } @all_problem_sets)[0];
	$set->{set_params} = {} unless defined $set->{set_params};
	$set->{set_type}   = $s->{set_type};
}

my @merged_user_sets = @{ clone(\@all_user_sets) };

# Merge the sets

for my $user_set (@merged_user_sets) {
	my $set = (grep { $_->{course_name} eq $user_set->{course_name} && $_->{set_name} eq $user_set->{set_name} }
			@all_problem_sets)[0];

	# override problem set dates with userset dates if exist
	my $dates = clone($set->{set_dates});
	for my $d (keys %{ $user_set->{set_dates} }) {
		$dates->{$d} = $user_set->{set_dates}->{$d};
	}

	# Determine params and dates overrides
	my $params = clone($set->{set_params});
	for my $key (keys %{ $user_set->{set_params} }) {
		$params->{$key} = $user_set->{set_params}->{$key};
	}

	$user_set->{set_params}  = $params;
	$user_set->{set_dates}   = $dates;
	$user_set->{set_version} = 1                   unless defined($user_set->{set_version});
	$user_set->{set_type}    = $set->{set_type}    unless defined($user_set->{set_type});
	$user_set->{set_visible} = $set->{set_visible} unless defined($user_set->{set_visible});
}

# Login as an instructor.  frink is an instructor in course_id: 1 (Precalculus)
$t->post_ok('/webwork3/api/login' => json => { username => 'frink', password => 'frink' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'frink')->json_is('/user/is_admin' => false);

my @precalc_user_sets = grep { $_->{course_name} eq 'Precalculus' } @all_user_sets;

# Get all user sets for the Precalc course (course_id: 1)
$t->get_ok('/webwork3/api/courses/1/user-sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $precalc_user_sets_from_db = $t->tx->res->json;

# Need to fetch the problem set for HW #1.  Grab this before cleaning ids.
my $hw1_user_set = clone((grep { $_->{set_name} eq 'HW #1' } @$precalc_user_sets_from_db)[0]);

for (@$precalc_user_sets_from_db) {
	removeIDs($_);
	cleanUndef($_);
}

is_deeply($precalc_user_sets_from_db, \@precalc_user_sets, 'userSets: get all user sets for one course.');

$t->get_ok("/webwork3/api/courses/1/sets/$hw1_user_set->{set_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $hw1 = $t->tx->res->json;

# Get all user sets for a particular set.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $hw1_user_sets_from_db = $t->tx->res->json;

for (@$hw1_user_sets_from_db) {
	removeIDs($_);
	cleanUndef($_);
}

my @tmp                     = grep { $_->{set_name} eq 'HW #1' && $_->{course_name} eq 'Precalculus' } @all_user_sets;
my $hw1_user_sets_from_file = clone(\@tmp);

delete $_->{course_name} for (@$hw1_user_sets_from_file);

is_deeply($hw1_user_sets_from_db, $hw1_user_sets_from_file, 'userSets: get all user sets for a single homework set.');

# Get all users sets for a single user.
# First get all users from the Precalculus course and find the user_id of 'homer'.
$t->get_ok('/webwork3/api/courses/1/global-courseusers')->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $precalc_users = $t->tx->res->json;
my $homer         = (grep { $_->{username} eq 'homer' } @$precalc_users)[0];

$t->get_ok("/webwork3/api/courses/1/users/$homer->{user_id}/sets");

my $homer_sets = $t->tx->res->json;

@tmp = grep { $_->{username} eq 'homer' && $_->{course_name} eq 'Precalculus' } @all_user_sets;
my $homer_user_sets_from_file = clone(\@tmp);

for (@$homer_sets) { removeIDs($_); cleanUndef($_); }
delete $_->{course_name} for (@$homer_user_sets_from_file);

is_deeply($homer_sets, $homer_user_sets_from_file, 'getUserSets: get all users sets for a single user.');

# Add one user set.

my $user_set_params = {
	username    => 'otto',
	set_visible => true,
	set_dates   => {
		open            => $hw1->{set_dates}{open} + 200,
		reduced_scoring => $hw1->{set_dates}{reduced_scoring} + 200,
		due             => $hw1->{set_dates}{due},
		answer          => $hw1->{set_dates}{answer} + 500
	}
};

# need the user_id of this user
$t->get_ok('/webwork3/api/courses/1/global-courseusers')->status_is(200);
my $course_users = $t->tx->res->json;

my $otto_user = (grep { $_->{username} eq $user_set_params->{username} } @$course_users)[0];

$t->post_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users" => json => $user_set_params)->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/username' => 'otto')
	->json_is('/set_visible' => true)->json_is('/set_dates/open' => $user_set_params->{set_dates}{open});

my $added_user_set = $t->tx->res->json;

# Update the user set

$user_set_params->{set_visible} = false;
$user_set_params->{set_dates}{answer} = $user_set_params->{set_dates}{answer} + 500;

$t->put_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}" => json => $user_set_params)
	->content_type_is('application/json;charset=UTF-8')->status_is(200)->json_is('/set_visible' => false)
	->json_is('/set_dates/answer' => $user_set_params->{set_dates}{answer});

# Test for exceptions

# Try to get all usersets for a set that is not in the course.
$t->get_ok('/webwork3/api/courses/1/sets/99/users')->status_is(500)
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# Try to create a usersets for a set that is not in the course.
$t->post_ok('/webwork3/api/courses/1/sets/99/users' => json => $user_set_params)->status_is(500)
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# Try to update a single user set for a user that is not in the course.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/10")->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to delete a single user set for a user that is not in the course.
$t->delete_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/10")->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Try to update a single user set for a user that is not in the course.
$t->put_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/10" => { set_visible => false })->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserNotInCourse');

# Some cleanup to restore the database
# Delete a user set
$t->delete_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}")
	->content_type_is('application/json;charset=UTF-8')->status_is(200);

# And check that the problem set is no longer in the db.
$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users/$otto_user->{user_id}")->status_is(500)
	->json_is('/exception' => 'DB::Exception::UserSetNotInCourse');

# Check some permissions as a student.  Logout as instructor and then login as a student.
$t->post_ok('/webwork3/api/logout')->status_is(200);

$t->post_ok('/webwork3/api/login' => json => { username => 'bart', password => 'bart' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'bart')->json_is('/user/is_admin' => false);

my $bart = $t->tx->res->json->{user};

# Make sure a student can access own user sets
$t->get_ok("/webwork3/api/courses/1/users/$bart->{user_id}/sets")->status_is(200);

my $bart_user_sets = $t->tx->res->json;

$t->get_ok("/webwork3/api/courses/1/sets/$bart_user_sets->[0]{set_id}/users/$bart->{user_id}")->status_is(200);

# Make sure that a student can't access other routes
$t->get_ok('/webwork3/api/courses/1/user-sets')->status_is(403)
	->json_is('/msg' => 'The user does not have permission for the route');

$t->get_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users")->status_is(403)
	->json_is('/msg' => 'The user does not have permission for the route');

$t->post_ok("/webwork3/api/courses/1/sets/$hw1->{set_id}/users" => json => {})->status_is(403)
	->json_is('/msg' => 'The user does not have permission for the route');

$t->put_ok("/webwork3/api/courses/1/sets/$bart_user_sets->[0]{set_id}/users/$bart->{user_id}" => json =>
		{ set_visible => false })->status_is(403);

$t->delete_ok("/webwork3/api/courses/1/sets/$bart_user_sets->[0]{set_id}/users/$bart->{user_id}")->status_is(403);

done_testing;

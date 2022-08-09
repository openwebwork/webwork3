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

use TestUtils qw/loadCSV removeIDs/;

# Test the api with common 'courses/sets' routes.

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
my $t = Test::Mojo->new(WeBWorK3 => $config);

# First run tests as logged in as an instructor
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => 0);

# Load all problems from the CVS files.
my @problems_from_csv = loadCSV(
	"$main::ww3_dir/t/db/sample_data/problems.csv",
	{
		non_neg_int_fields       => ['problem_number'],
		param_non_neg_int_fields => ['library_id']
	}
);
my @user_problems_from_csv = loadCSV(
	"$main::ww3_dir/t/db/sample_data/user_problems.csv",
	{
		non_neg_int_fields => [ 'problem_number', 'seed' ]
	}
);

# Filter out Arithmetic problems
my @arith_problems      = grep { $_->{course_name} eq 'Arithmetic' } @problems_from_csv;
my @arith_user_problems = grep { $_->{course_name} eq 'Arithmetic' } @user_problems_from_csv;

# Filter out 'HW #1'
my @arith_problems1      = grep { $_->{set_name} eq 'HW #1' } @arith_problems;
my @arith_user_problems1 = grep { $_->{set_name} eq 'HW #1' } @arith_user_problems;

for my $problem (@arith_problems1) {
	for my $key (qw/set_name course_name/) {
		delete $problem->{$key};
	}
}

for my $problem (@arith_user_problems1) {
	$problem->{problem_params}  = {} unless defined($problem->{problem_params});
	$problem->{problem_version} = 1  unless defined($problem->{problem_version});
}

# Get all of the users and homework sets in Arithmetic course (needed later)

$t->get_ok('/webwork3/api/courses/4/global-courseusers')->status_is(200)
	->content_type_is('application/json;charset=UTF-8');
my $all_users = $t->tx->res->json;

$t->get_ok('/webwork3/api/courses/4/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');
my $sets = $t->tx->res->json;
my $hw1  = (grep { $_->{set_name} eq 'HW #1' } @$sets)[0];

# Get all Arithmetic problems (course_id: 4)

$t->get_ok('/webwork3/api/courses/4/problems')->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $problems_from_db = $t->tx->res->json;
for my $problem (@$problems_from_db) { removeIDs($problem); }

is_deeply(\@arith_problems, $problems_from_db, 'getGlobalProblems: get all problems');

# Get all user problems for a single set.

$t->get_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/user-problems")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

my $user_problems_from_db = $t->tx->res->json;
for my $problem (@$user_problems_from_db) { removeIDs($problem); }

# the status needs be returned to a numerical value.
$_->{status} += 0 for (@$user_problems_from_db);

@arith_user_problems =
	sort { $a->{username} cmp $b->{username} || $a->{problem_number} <=> $b->{problem_number} } @arith_user_problems;
my @user_problems_from_db =
	sort { $a->{username} cmp $b->{username} || $a->{problem_number} <=> $b->{problem_number} } @$user_problems_from_db;

is_deeply(\@user_problems_from_db, \@arith_user_problems, 'getUserProblems: get all problems for a set in a course.');

# Get all user problems in a course for a single user. Find user 'ralph'

my $ralph = (grep { $_->{username} eq 'ralph' } @$all_users)[0];

$t->get_ok("/webwork3/api/courses/4/users/$ralph->{user_id}/problems");
my $ralph_user_problems = $t->tx->res->json;

for my $problem (@$ralph_user_problems) {
	removeIDs($problem);
}

my @ralph_user_problems_from_file = grep { $_->{username} eq 'ralph' } @arith_user_problems;
# For comparision make sure the loaded status are printed to 5 digits.
$_->{status} += 0 for (@$ralph_user_problems);

is_deeply(\@ralph_user_problems_from_file,
	$ralph_user_problems, 'getUserProblems: get all problems for a set in a course.');

# New to make a new problem first

$t->post_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/problems" => json => {
		problem_params => {
			file_path => 'this/is/not/a/real/path.pg'
		}
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/set_id' => $hw1->{set_id});

my $new_problem = $t->tx->res->json;

# Create a new user problem

$t->post_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems" => json => {
		seed           => 5421,
		problem_number => $new_problem->{problem_number},
		problem_params => {
			weight => 3
		}
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/seed' => 5421)
	->json_is('/problem_params/weight' => 3);

my $new_user_problem = $t->tx->res->json;

# get the user problem

$t->get_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}")
	->status_is(200)->json_is('/seed' => 5421)->json_is('/problem_params/weight' => 3);

# Update the user problem

$t->put_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}"
		=> json => { seed => 789 })->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/seed' => 789);

# Check that a student has the correct access
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => 0);
$t->post_ok('/webwork3/api/login' => json => { username => 'ralph', password => 'ralph' })->status_is(200);

# get all of ralph's problems
$t->get_ok("/webwork3/api/courses/4/users/$ralph->{user_id}/problems")->status_is(200);

# get a single problem
$t->get_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}")
	->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/seed' => 789)
	->json_is('/problem_params/weight' => 3);

# Update a problem
$t->put_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}"
		=> json => { status => 0.5 })->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/status' => 0.5);

# A student shouldn't be able to create a new problem or delete
$t->post_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems" => json => {
		seed           => 5421,
		problem_number => $new_problem->{problem_number},
		problem_params => {
			weight => 3
		}
	}
)->status_is(403);

$t->delete_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}")
	->status_is(403);

# Make sure that a user that is in the course, cannot get or update a user problem that is not one's own.
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => 0);
$t->post_ok('/webwork3/api/login' => json => { username => 'moe', password => 'moe' })->status_is(200);

# Check that moe is in the course
my $moe = (grep { $_->{username} eq 'moe' } @$all_users)[0];

$t->get_ok("/webwork3/api/users/$moe->{user_id}/courses")->status_is(200);
my $moes_courses = $t->tx->res->json;

ok((grep { $_->{course_name} eq 'Arithmetic' } @$moes_courses)[0], 'Check that moe is in the Arithmetic course.');

# Try to get ralph's user problems
$t->get_ok("/webwork3/api/courses/4/users/$ralph->{user_id}/problems")->status_is(403);

# Try to get a single problem
$t->get_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}")
	->status_is(403);

# Try to update a single problem
$t->put_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}"
		=> json => { status => 0.5 })->status_is(403);

# Switch back to the instructor and delete the user problem
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => 0);
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200);

$t->delete_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/users/$ralph->{user_id}/problems/$new_user_problem->{user_problem_id}")
	->status_is(200)->content_type_is('application/json;charset=UTF-8');

# Delete the added problem

$t->delete_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

done_testing;

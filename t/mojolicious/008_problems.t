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
my $t = Test2::MojoX->new(WeBWorK3 => $config);

# First run tests as logged in as an instructor
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Load all problems from the CVS files.
my @problems_from_csv = loadCSV(
	"$main::ww3_dir/t/db/sample_data/problems.csv",
	{
		non_neg_int_fields       => ['problem_number'],
		param_non_neg_int_fields => ['library_id']
	}
);

# Filter out Arithmetic problems
my @arith_problems = grep { $_->{course_name} eq 'Arithmetic' } @problems_from_csv;

# Filter out 'HW #1'
my @arith_problems1 = grep { $_->{set_name} eq 'HW #1' } @arith_problems;

for my $problem (@arith_problems) {
	for my $key (qw/set_name course_name/) {
		delete $problem->{$key};
	}
}

# Get all of the homework sets in Arithmetic course (needed later)

$t->get_ok('/webwork3/api/courses/4/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $sets = $t->tx->res->json;

my $hw1 = (grep { $_->{set_name} eq 'HW #1' } @$sets)[0];

# Get all Arithmetic problems (course_id: 4)

$t->get_ok('/webwork3/api/courses/4/problems')->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $problems_from_db = $t->tx->res->json;
for my $problem (@$problems_from_db) { removeIDs($problem); }

is($problems_from_db, \@arith_problems, 'getGlobalProblems: get all problems');

# Add a new problem to a set.

$t->post_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/problems" => json => {
		problem_params => {
			file_path => 'this/is/not/a/real/path.pg'
		}
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/set_id' => $hw1->{set_id});

my $new_problem = $t->tx->res->json;

# Get a single problem

$t->get_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/set_id' => $new_problem->{set_id})
	->json_is('/problem_number' => $new_problem->{problem_number});

# Update the problem
$t->put_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}" => json => {
		problem_params => {
			weight => 3
		}
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/problem_number' => $new_problem->{problem_number})->json_is('/problem_params/weight' => 3);

# Make sure that a student cannot access the global problem routes
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => false);
$t->post_ok('/webwork3/api/login' => json => { username => 'ralph', password => 'ralph' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'ralph')->json_is('/user/is_admin' => false);

my $logged_in_user = $t->tx->res->json('/user');

# Make sure ralph is enrolled in the Arithmetic course by getting the course users
$t->get_ok("/webwork3/api/users/$logged_in_user->{user_id}/courses");

my $user_courses = $t->tx->res->json;
is(scalar(grep { $_->{course_name} eq 'Arithmetic' } @$user_courses), 1, 'The user ralph is enrolled in the course.');

# a student should have access to getting global problems
$t->get_ok('/webwork3/api/courses/4/problems')->status_is(200)->content_type_is('application/json;charset=UTF-8');

my $all_problems = $t->tx->res->json;

# Get a single problem
my $set_problem_id = $all_problems->[ scalar(@$all_problems) - 1 ]->{set_problem_id};

$t->get_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$set_problem_id")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

# But not to adding, updating or deleting a problem
$t->post_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/problems" => json => {
		problem_params => {
			file_path => 'this/is/not/a/real/path.pg'
		}
	}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->put_ok(
	"/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}" => json => {
		problem_params => {
			weight => 3
		}
	}
)->status_is(403)->content_type_is('application/json;charset=UTF-8');

$t->delete_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}")->status_is(403)
	->content_type_is('application/json;charset=UTF-8');

# Make sure that a student not enrolled in the course has access to getting global problems
# for that course.
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => false);
$t->post_ok('/webwork3/api/login' => json => { username => 'ned', password => 'ned' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'ned')->json_is('/user/is_admin' => false);

$logged_in_user = $t->tx->res->json('/user');

# check that ned is not in the course
$t->get_ok("/webwork3/api/users/$logged_in_user->{user_id}/courses");

$user_courses = $t->tx->res->json;

is(scalar(grep { $_->{course_name} eq 'Arithmetic' } @$user_courses), 0, 'The user ned is not enrolled in the course.');

$t->get_ok('/webwork3/api/courses/4/problems')->status_is(403)->content_type_is('application/json;charset=UTF-8');

# Finally, delete the new problem to restore the db to it's pretest state.
$t->post_ok('/webwork3/api/logout')->status_is(200)->json_is('/logged_in' => false);
$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200);

$t->delete_ok("/webwork3/api/courses/4/sets/$hw1->{set_id}/problems/$new_problem->{set_problem_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8');

done_testing;

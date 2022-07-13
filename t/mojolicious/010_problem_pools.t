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

use DB::Schema;
use Clone qw/clone/;
use Mojo::JSON qw/true false/;
use YAML::XS qw/LoadFile/;
use DateTime::Format::Strptime;
use List::MoreUtils qw/firstval/;

use DB::TestUtils qw/loadCSV removeIDs/;

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');
# Test the api with common "users" routes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

# Connect to the database.
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $t = Test::Mojo->new(WeBWorK3 => $config);

# Login as an user with instructor privileges in a course (Arithmetic; course_id: 4)
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Load the review sets from the CSV file
my @pool_problems_from_file = loadCSV(
	"$main::ww3_dir/t/db/sample_data/pool_problems.csv",
	{
		param_non_neg_int_fields => ['library_id']
	}
);

my @arith_pool_problems = grep { $_->{course_name} eq 'Arithmetic' } @pool_problems_from_file;
for my $problem (@arith_pool_problems) {
	# delete $problem->{params};
	delete $problem->{course_name};
}

# Get an array of unique problem pools by pool_name.
my %seen;
my @arith_problem_pools = grep { !$seen{ $_->{pool_name} }++ } @arith_pool_problems;
@arith_problem_pools = sort { $a->{pool_name} cmp $b->{pool_name} } @arith_problem_pools;

# Get all problem pools in Arithemtic
$t->get_ok('/webwork3/api/courses/4/problem-pools')->content_type_is('application/json;charset=UTF-8')->status_is(200);

my @arith_pools_from_db = sort { $a->{pool_name} cmp $b->{pool_name} } @{ $t->tx->res->json };

# We want to keep the ids from the pools, so first make a clone to compare
my $arith_pools = clone(\@arith_pools_from_db);
for my $pool (@$arith_pools) {
	removeIDs($pool);
}

is_deeply($arith_pools, \@arith_problem_pools, 'getProblemPools: get problem pools from one course');

$t->get_ok("/webwork3/api/courses/4/problem-pools/$arith_pools_from_db[0]->{problem_pool_id}")->status_is(200)
	->json_is('/pool_name' => $arith_problem_pools[0]->{pool_name});

# Add a new Problem Pool

$t->post_ok(
	'/webwork3/api/courses/4/problem-pools' => json => {
		pool_name => 'integer powers'
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/pool_name' => 'integer powers');

my $added_problem_pool = $t->tx->res->json;

# Update the problem Pool

$t->put_ok(
	"/webwork3/api/courses/4/problem-pools/$added_problem_pool->{problem_pool_id}" => json => {
		pool_name => 'adding decimals'
	}
)->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/pool_name' => 'adding decimals');

# Delete the problem pool

$t->delete_ok("/webwork3/api/courses/4/problem-pools/$added_problem_pool->{problem_pool_id}")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/pool_name' => 'adding decimals');

# Test Pool Problems

use Data::Dumper;
print Dumper $arith_pools_from_db[0];
print Dumper \@arith_pool_problems;

my @arith_pool1 = grep { $_->{pool_name} eq $arith_pools_from_db[0]->{pool_name} } @arith_pool_problems;
print Dumper \@arith_pool1;

$t->get_ok("/webwork3/api/courses/4/problem-pools/$arith_pools_from_db[0]->{problem_pool_id}/pool-problems")->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/pool_name' => 'adding decimals');

print Dumper $t->tx->res->json;

# Make sure that students don't have access to Problem Pools

# Make sure that students don't have access to Problem Pools

done_testing();

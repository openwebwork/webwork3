#!/usr/bin/env perl

# This tests the basic database CRUD functions of Problem Pools and Pool Problems .

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Test::More;
use Test::Exception;
use YAML::XS qw/LoadFile/;
use Clone qw/clone/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs/;

# Load the database
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

my $problem_pool_rs = $schema->resultset('ProblemPool');

# Load pool problems from the csv files.
my @pool_problems_from_file = loadCSV(
	"$main::ww3_dir/t/db/sample_data/pool_problems.csv",
	{
		param_non_neg_int_fields => ['library_id']
	}
);

# To find the problem pools, remove duplicates and remove the params field.
my @problem_pools_from_file = sort { $a->{pool_name} cmp $b->{pool_name} } @{ clone(\@pool_problems_from_file) };
my %seen;
@problem_pools_from_file = grep { !$seen{ $_->{pool_name} }++ } @problem_pools_from_file;
for my $pool (@problem_pools_from_file) {
	delete $pool->{params};
}

# get only problem_pools for Precalculus course.

my @precalc_pools_from_file = grep { $_->{course_name} eq 'Precalculus' } @{ clone(\@problem_pools_from_file) };
my @problem_pools_from_db   = $problem_pool_rs->getAllProblemPools();
@problem_pools_from_db = sort { $a->{pool_name} cmp $b->{pool_name} } @problem_pools_from_db;
for my $pool (@problem_pools_from_db) {
	removeIDs($pool);
}

is_deeply(\@problem_pools_from_file, \@problem_pools_from_db, 'getAllProblemPools: find all problem pools');

my @precalc_pools = $problem_pool_rs->getProblemPools(info => { course_name => 'Precalculus' });

for my $pool (@precalc_pools) {
	removeIDs($pool);
	$pool->{course_name} = 'Precalculus';
}

is_deeply(\@precalc_pools_from_file, \@precalc_pools, 'getProblemPools: get all problem pools from a single course');

# Get a problem pool
my $pool_to_fetch = $problem_pools_from_file[0];

my $fetched_pool = $problem_pool_rs->getProblemPool(info => $pool_to_fetch);
removeIDs($fetched_pool);
$fetched_pool->{course_name} = $problem_pools_from_file[0]->{course_name};

is_deeply($pool_to_fetch, $fetched_pool, 'getProblemPool: get a single pool from a course');

# Try to get a problem pool from a course that doesn't exist.
throws_ok {
	$problem_pool_rs->getProblemPool(info => { course_name => 'not existent course', pool_name => 'adding fractions' });
}
'DB::Exception::CourseNotFound', 'getProblemPool: get a problem pool from a non-existent course';

# Try to get a problem pool from a course, but the pool doesn't exist.
throws_ok {
	$problem_pool_rs->getProblemPool(info => { course_name => 'Arithmetic', pool_name => 'non_existent_pool' });
}
'DB::Exception::PoolNotInCourse', 'getProblemPool: get a problem pool from a non-existent course';

# Add a problem pool
my $course_name = 'Arithmetic';
my $pool_name   = 'subtracting fractions';

my $pool2 = $problem_pool_rs->addProblemPool(
	params => {
		course_name => $course_name,
		pool_name   => $pool_name
	}
);
removeIDs($pool2);

is_deeply(
	{
		pool_name => $pool_name
	},
	$pool2,
	'addProblemPool: add a new problem pool to a course'
);

# Try to add a pool that already exists.
throws_ok {
	$problem_pool_rs->addProblemPool(
		params => {
			course_name => 'Arithmetic',
			pool_name   => 'adding fractions'
		}
	);
}
'DB::Exception::PoolAlreadyInCourse', 'addProblemPool: pool already exists';

# Try to add a pool with an invalid field.
throws_ok {
	$problem_pool_rs->addProblemPool(
		params => {
			course_name => 'Arithmetic',
			pool_name   => 'dividing fractions',
			other_field => 'XXX'
		}
	);
}
'DBIx::Class::Exception', 'addProblemPool: add a pool with non-valid field';

# Update an existing problem pool.
my $updated_pool = { pool_name => 'subtracting fractions with like denominators', };

my $updated_pool_from_db = $problem_pool_rs->updateProblemPool(
	info   => { course_name => 'Arithmetic', pool_name => 'subtracting fractions' },
	params => $updated_pool
);
$updated_pool_from_db->{course_name} = 'Arithmetic';

removeIDs($updated_pool_from_db);
$updated_pool->{course_name} = 'Arithmetic';

is_deeply($updated_pool, $updated_pool_from_db, 'updateProblemPool: update the name of a problem pool');

# TODO: Try to update a pool that doesn't exist.

# Try to get a problem pool from a course that doesn't exist.
throws_ok {
	$problem_pool_rs->updateProblemPool(
		info  => { course_name => 'non_existent_course', pool_name => 'XXXX' },
		parms => $updated_pool
	);
}
'DB::Exception::CourseNotFound', 'udpateProblemPool: update a problem pool from a non-existent course';

# Try to get a non-existent problem pool from a course.
throws_ok {
	$problem_pool_rs->updateProblemPool(
		info   => { course_name => 'Arithmetic', pool_name => 'non_existent_pool' },
		params => $updated_pool
	);
}
'DB::Exception::PoolNotInCourse', 'updateProblemPool: update a problem pool from a non-existent course';

# Get all PoolProblems from within a pool
my @pool_problems = $problem_pool_rs->getPoolProblems(
	info => {
		course_name => 'Precalculus',
		pool_name   => $precalc_pools_from_file[0]->{pool_name}
	}
);

# Get a PoolProblem (a problem within a ProblemPool).
my $prob2 = $pool_problems_from_file[0];

my $pool_problem2 = $problem_pool_rs->getPoolProblem(info => $prob2);

is($prob2->{library_id}, $pool_problem2->{library_id}, 'getPoolProblem: get a single problem from a problem pool');

# Get a random PoolProblem.
my $random_prob = $problem_pool_rs->getPoolProblem(
	info => {
		course_name => $prob2->{course_name},
		pool_name   => $prob2->{pool_name}
	}
);

my @probs3 =
	grep { $_->{course_name} eq $prob2->{course_name} and $_->{pool_name} eq $prob2->{pool_name} }
	@pool_problems_from_file;
my @lib_ids = map  { $_->{params}->{library_id} } @probs3;
my @arr     = grep { $_ == $random_prob->{params}->{library_id} } @lib_ids;

ok(scalar(@arr) == 1, 'getPoolProblem: get a random problem from a problem pool');

# Add a Problem to a pool.
my $prob_to_add->{params} = { library_id => 8332 };
my $added_problem = $problem_pool_rs->addProblemToPool(params => { %$updated_pool, %$prob_to_add });

is(
	$prob_to_add->{params}->{library_id},
	$added_problem->{params}->{library_id},
	'addProblemToPool: adding a problem to an existing pool.'
);

# Check that adding a problem to a non-existence course fails.
throws_ok {
	$problem_pool_rs->addProblemToPool(
		params => {
			course_name => 'non_existing_course',
			pool_name   => 'adding fractions',
			%$prob_to_add
		}
	);
}
'DB::Exception::CourseNotFound', 'addProblemToPool: try to add to a nonexisting course';

# Check that adding a problem to a non-existence pool fails.
throws_ok {
	$problem_pool_rs->addProblemToPool(
		params => {
			course_name => $updated_pool->{course_name},
			pool_name   => 'non_existent_pool_name',
			%$prob_to_add
		}
	);
}
'DB::Exception::PoolNotInCourse', 'addProblemToPool: try to add to a nonexisting pool';

# Update a pool problem.
my $course_pool_problem_info = {%$updated_pool_from_db};
$course_pool_problem_info->{pool_problem_id} = $added_problem->{pool_problem_id};

my $updated_library_id = 2839;

my $updated_pool_problem = $problem_pool_rs->updatePoolProblem(
	info   => $course_pool_problem_info,
	params => { params => { library_id => $updated_library_id } }
);

is(
	$updated_library_id,
	$updated_pool_problem->{params}->{library_id},
	'updatePoolProblem: update an existing problem in an existing pool.'
);

# Check that updating a problem to a non-existence course fails.
throws_ok {
	$problem_pool_rs->updatePoolProblem(
		info => {
			course_name     => 'non_existing_course',
			pool_name       => 'adding fractions',
			pool_problem_id => $added_problem->{pool_problem_id}
		},
		params => {
			params => {
				library_id => $updated_library_id
			}
		}
	);
}
'DB::Exception::CourseNotFound', 'updatePoolProblem: try to update a nonexisting course';

# Check that updating a problem to a non-existence course fails.
throws_ok {
	$problem_pool_rs->updatePoolProblem(
		info => {
			course_name     => $updated_pool->{course_name},
			pool_name       => 'non_existent_pool_name',
			pool_problem_id => $added_problem->{pool_problem_id}
		},
		params => { library_id => $updated_library_id }
	);
}
'DB::Exception::PoolNotInCourse', 'updatePoolProblem: try to update  a nonexisting pool';

# Check that updating a problem to a non-existing problem fails.
throws_ok {
	$problem_pool_rs->updatePoolProblem(
		info => {
			course_name     => $updated_pool->{course_name},
			pool_name       => $updated_pool->{pool_name},
			pool_problem_id => -999
		},
		params => { library_id => $updated_library_id }
	);
}
'DB::Exception::PoolProblemNotInPool', 'updatePoolProblem: try to update a nonexisting problem';

# Delete a problem pool
my $pool_to_delete = $problem_pool_rs->deleteProblemPool(info => $updated_pool);
removeIDs($pool_to_delete);
$pool_to_delete->{course_name} = 'Arithmetic';
is_deeply($updated_pool, $pool_to_delete, 'deleteProblemPool: delete an existing problem pool');

# Ensure that the problem_pool table is restored.
@problem_pools_from_db = $problem_pool_rs->getAllProblemPools();
@problem_pools_from_db = sort { $a->{pool_name} cmp $b->{pool_name} } @problem_pools_from_db;
for my $pool (@problem_pools_from_db) {
	removeIDs($pool);
}

is_deeply(\@problem_pools_from_file, \@problem_pools_from_db, 'check: Ensure that the problem_pool table is restored.');

done_testing;

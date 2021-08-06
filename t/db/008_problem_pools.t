#
# This tests the basic database CRUD functions of Pool Problems.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use lib "$main::lib_dir";

# use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;
use Try::Tiny;
use Carp;
use YAML::XS qw/LoadFile/;

use List::MoreUtils qw/uniq/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;

# load some configuration for the database:

my $config = LoadFile("$main::lib_dir/../conf/webwork3.yml");

my $schema;
# load the database
if ($config->{database} eq 'sqlite') {
	$schema  = DB::Schema->connect($config->{sqlite_dsn});
} elsif ($config->{database} eq 'mariadb') {
	$schema  = DB::Schema->connect($config->{mariadb_dsn},$config->{database_user},$config->{database_password});
}

# $schema->storage->debug(1);  # print out the SQL commands.

## load problem pools from the csv files:

my @pool_problems_from_file = loadCSV("$main::test_dir/sample_data/pool_problems.csv");

my @problem_pools_from_file = map {
	{%$_};
} @pool_problems_from_file;    # copy the array
for my $pool (@problem_pools_from_file) {
	delete $pool->{library_id};
	delete $pool->{params};
}

## get an array of unique problem pools by pool_name
my %seen;
@problem_pools_from_file = grep { !$seen{ $_->{pool_name} }++ } @problem_pools_from_file;

my $problem_pool_rs = $schema->resultset("ProblemPool");

my @problem_pools_from_db = $problem_pool_rs->getAllProblemPools();
for my $pool (@problem_pools_from_db) {
	removeIDs($pool);
}

my @precalc_pools_from_file = grep { $_->{course_name} eq "Precalculus" } @problem_pools_from_file;

is_deeply( \@problem_pools_from_file, \@problem_pools_from_db, "getAllProblemPools: find all problem pools" );

my @precalc_pools = $problem_pool_rs->getProblemPools( { course_name => "Precalculus" } );
for my $pool (@precalc_pools) {
	removeIDs($pool);
	$pool->{course_name} = "Precalculus";
}

is_deeply( \@precalc_pools_from_file, \@precalc_pools, "getProblemPools: get all problem pools from a single course" );

## get a problem pool

my $pool_to_fetch = $problem_pools_from_file[0];

my $fetched_pool = $problem_pool_rs->getProblemPool($pool_to_fetch);
removeIDs($fetched_pool);
$fetched_pool->{course_name} = $problem_pools_from_file[0]->{course_name};

is_deeply( $pool_to_fetch, $fetched_pool, "getProblemPool: get a single pool from a course" );

## throws_ok to get a problem pool from a course that doesn't exist.

throws_ok {
	$problem_pool_rs->getProblemPool( { course_name => "not existent course", pool_name => "adding fractions" } );
}
"DB::Exception::CourseNotFound", "getProblemPool: get a problem pool from a non-existent course";

## throws_ok to get a problem pool from a course, but the pool doesn't exist.

throws_ok {
	$problem_pool_rs->getProblemPool( { course_name => "Arithmetic", pool_name => "non_existent_pool" } );
}
"DB::Exception::PoolNotInCourse", "getProblemPool: get a problem pool from a non-existent course";

## add a problem pool

my $course_name = 'Arithmetic';
my $pool_name   = 'subtracting fractions';

my $pool2 = $problem_pool_rs->addProblemPool( { course_name => $course_name }, { pool_name => $pool_name } );
removeIDs($pool2);

is_deeply(
	{
		# course_name => $course_name,
		pool_name => $pool_name
	},
	$pool2,
	"addProblemPool: add a new problem pool to a course"
);

## addProblemPool to a pool that already exists

throws_ok {
	$problem_pool_rs->addProblemPool( { course_name => 'Arithmetic' }, { pool_name => "adding fractions" } );
}
"DB::Exception::PoolAlreadyInCourse", "addProblemPool: pool already exists";

## addProblemPool with a pool with non-valid field

throws_ok {
	$problem_pool_rs->addProblemPool( { course_name => 'Arithmetic' },
		{ pool_name => "multiplying fractions", other_field => "XXX" } );
}
"DBIx::Class::Exception", "addProblemPool: add a pool with non-valid field";

## update an existing problem pool

my $updated_pool = { pool_name => "subtracting fractions with like denominators", };

my $updated_pool_from_db =
	$problem_pool_rs->updateProblemPool( { course_name => 'Arithmetic', pool_name => 'subtracting fractions' },
	$updated_pool );
$updated_pool_from_db->{course_name} = 'Arithmetic';

removeIDs($updated_pool_from_db);
$updated_pool->{course_name} = 'Arithmetic';

is_deeply( $updated_pool, $updated_pool_from_db, "updateProblemPool: update the name of a problem pool" );

## throws_ok to update a pool that doesn't exist

## throws_ok to get a problem pool from a course that doesn't exist.

throws_ok {
	$problem_pool_rs->updateProblemPool( { course_name => 'non_existent_course', pool_name => 'XXXX' }, $updated_pool );
}
"DB::Exception::CourseNotFound", "udpateProblemPool: update a problem pool from a non-existent course";

## throws_ok to get a problem pool from a course, but the pool doesn't exist.

throws_ok {
	$problem_pool_rs->updateProblemPool( { course_name => "Arithmetic", pool_name => "non_existent_pool" },
		$updated_pool );
}
"DB::Exception::PoolNotInCourse", "updateProblemPool: get a problem pool from a non-existent course";

## get a PoolProblem (a problem within a ProblemPool)

my $prob2 = $pool_problems_from_file[0];

my $pool_problem2 = $problem_pool_rs->getPoolProblem($prob2);

is( $prob2->{library_id}, $pool_problem2->{library_id}, "getPoolProblem: get a single problem from a problem pool" );

## get a random PoolProblem

my $random_prob = $problem_pool_rs->getPoolProblem(
	{   course_name => $prob2->{course_name},
		pool_name   => $prob2->{pool_name}
	}
);

my @probs3 = grep { $_->{course_name} eq $prob2->{course_name} and $_->{pool_name} eq $prob2->{pool_name} }
	@pool_problems_from_file;

my @lib_ids = map { $_->{library_id} } @probs3;

my @arr = grep { $_ == $random_prob->{library_id} } @lib_ids;

ok( scalar(@arr) == 1, "getPoolProblem: get a random problem from a problem pool" );

## add a Problem to a pool

my $prob_to_add = { library_id => 8332 };

my $added_problem = $problem_pool_rs->addProblemToPool( $updated_pool, $prob_to_add );

is( $prob_to_add->{library_id},
	$added_problem->{library_id},
	"addProblemToPool: adding a problem to an existing pool."
);

### check that adding a problem to a non-existence course fails

throws_ok {
	$problem_pool_rs->addProblemToPool(
		{   course_name => "non_existing_course",
			pool_name   => "adding fractions"
		},
		$prob_to_add
	);
}
"DB::Exception::CourseNotFound", "addProblemToPool: try to add to a nonexisting course";

### check that adding a problem to a non-existence pool fails

throws_ok {
	$problem_pool_rs->addProblemToPool(
		{   course_name => $updated_pool->{course_name},
			pool_name   => "non_existent_pool_name"
		},
		$prob_to_add
	);
}
"DB::Exception::PoolNotInCourse", "addProblemToPool: try to add to a nonexisting pool";

## update a pool problem

my $course_pool_problem_info = {%$updated_pool_from_db};
$course_pool_problem_info->{pool_problem_id} = $added_problem->{pool_problem_id};

my $updated_library_id = 2839;

my $updated_pool_problem =
	$problem_pool_rs->updatePoolProblem( $course_pool_problem_info, { library_id => $updated_library_id } );

is( $updated_library_id,
	$updated_pool_problem->{library_id},
	"updatePoolProblem: update an existing problem in an existing pool."
);

### check that updating a problem to a non-existence course fails

throws_ok {
	$problem_pool_rs->updatePoolProblem(
		{   course_name     => "non_existing_course",
			pool_name       => "adding fractions",
			pool_problem_id => $added_problem->{pool_problem_id}
		},
		{ library_id => $updated_library_id }
	);
}
"DB::Exception::CourseNotFound", "updatePoolProblem: try to update a nonexisting course";

### check that updating a problem to a non-existence course fails

throws_ok {
	$problem_pool_rs->updatePoolProblem(
		{   course_name     => $updated_pool->{course_name},
			pool_name       => "non_existent_pool_name",
			pool_problem_id => $added_problem->{pool_problem_id}
		},
		{ library_id => $updated_library_id }
	);
}
"DB::Exception::PoolNotInCourse", "updatePoolProblem: try to update  a nonexisting pool";

### check that updating a problem to a non-existing problem fails.

throws_ok {
	$problem_pool_rs->updatePoolProblem(
		{   course_name     => $updated_pool->{course_name},
			pool_name       => $updated_pool->{pool_name},
			pool_problem_id => -999
		},
		{ library_id => $updated_library_id }
	);
}
"DB::Exception::PoolProblemNotInPool", "updatePoolProblem: try to update a nonexisting problem";

## delete a problem pool
my $pool_to_delete = $problem_pool_rs->deleteProblemPool($updated_pool);
removeIDs($pool_to_delete);
$pool_to_delete->{course_name} = 'Arithmetic';

is_deeply( $updated_pool, $pool_to_delete, "deleteProblemPool: delete an existing problem pool" );

done_testing;

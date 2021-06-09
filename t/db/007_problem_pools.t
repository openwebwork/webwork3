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
use Carp;

use List::MoreUtils qw/uniq/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;


# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

## load problem pools from the csv files:

my @pool_problems_from_file = loadCSV("$main::test_dir/sample_data/pool_problems.csv");

my @problem_pools_from_file = @pool_problems_from_file;
for my $pool (@problem_pools_from_file) {
	delete $pool->{library_id};
	delete $pool->{params};
}

## get an array of unique problem pools by pool_name
my %seen;
@problem_pools_from_file = grep { ! $seen{$_->{pool_name}}++ } @problem_pools_from_file;

my $problem_pool_rs = $schema->resultset("ProblemPool");

my @problem_pools_from_db = $problem_pool_rs->getAllProblemPools(); 
for my $pool (@problem_pools_from_db) {
	removeIDs($pool);
}

my @precalc_pools_from_file = grep { $_->{course_name} eq "Precalculus"} @problem_pools_from_file; 

is_deeply(\@problem_pools_from_file,\@problem_pools_from_db,"getAllProblemPools: find all problem pools");

my @precalc_pools = $problem_pool_rs->getProblemPools({course_name => "Precalculus"});
for my $pool (@precalc_pools) {
	removeIDs($pool);
}

is_deeply(\@precalc_pools_from_file, \@precalc_pools, "getProblemPools: get all problem pools from a single course");

## get a problem pool

my $pool_to_fetch = $problem_pools_from_file[0];

my $fetched_pool = $problem_pool_rs->getProblemPool($pool_to_fetch);
removeIDs($fetched_pool); 

is_deeply($pool_to_fetch,$fetched_pool,"getProblemPool: get a single pool from a course");

## add a problem pool

my $course_name = 'Arithmetic';
my $pool_name = 'subtracting fractions';



my $pool2 = $problem_pool_rs->addProblemPool({course_name => $course_name},{pool_name => $pool_name});
removeIDs($pool2); 


is_deeply(
	{
		course_name => $course_name, pool_name => $pool_name
	},
	$pool2,
	"addProblemPool: add a new problem pool to a course"
);

## addProblemPool to a pool that already exists

dies_ok {
	$problem_pool_rs->addProblemPool({course_name => 'Arithmetic'},{pool_name => "adding fractions"});
} "addProblemPool: pool already exists";

## addProblemPool with a pool with non-valid field

dies_ok {
	$problem_pool_rs->addProblemPool({course_name => 'Arithmetic'},
		{pool_name => "multiplying fractions", other_field => "XXX"}
	);
} "addProblemPool: add a pool with non-valid field";

## update an existing problem pool

my $updated_pool = {
		pool_name => "subtracting fractions with like denominators"
	};

my $updated_pool_from_db = $problem_pool_rs->updateProblemPool(
		{course_name => 'Arithmetic',pool_name => 'subtracting fractions'},
		$updated_pool
	);

removeIDs($updated_pool_from_db);
$updated_pool->{course_name} = 'Arithmetic';

is_deeply($updated_pool,$updated_pool_from_db,
						"updateProblemPool: update the name of a problem pool");

## try to update a pool that doesn't exist

dies_ok {
	$problem_pool_rs->updateProblemPool(
		{course_name => 'Arithmetic',pool_name => 'XXXX'},
		$updated_pool
	);
} "updateProblemPool: update a pool that doesn't exist";


## delete a problem pool
my $pool_to_delete = $problem_pool_rs->deleteProblemPool($updated_pool);
removeIDs($pool_to_delete);

is_deeply($updated_pool,$pool_to_delete,
							"deleteProblemPool: delete an existing problem pool");

done_testing;

1; 
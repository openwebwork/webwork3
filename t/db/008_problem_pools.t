#!/usr/bin/env perl

# This tests the basic database CRUD functions of Problem Pools and Pool Problems .

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/loadPermissions addCourses addUsers addSets addProblemPools/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'course users' => sub ($schema) {
	# Add the neccessary sample data to the database.
	loadPermissions($schema, $ww3_dir);
	addCourses($schema, $ww3_dir);
	addUsers($schema, $ww3_dir);
	addSets($schema, $ww3_dir);
	addProblemPools($schema, $ww3_dir);

	my $problem_pool_rs = $schema->resultset('ProblemPool');

	# Load problem pools and pool problems from the JSON file.
	my $course_pool_problems = decode_json($ww3_dir->child('t/db/sample_data/pool_problems.json')->slurp);
	my @problem_pools_from_file;
	my @precalc_pools_from_file;    # Save precalculus problem pools.
	my @pool_problems_from_file;
	for my $course_info (@$course_pool_problems) {
		for my $problem_pool_info (@{ $course_info->{pools} }) {
			push(@problem_pools_from_file,
				{ course_name => $course_info->{course_name}, pool_name => $problem_pool_info->{pool_name} });
			push(@precalc_pools_from_file, $problem_pools_from_file[-1])
				if $course_info->{course_name} eq 'Precalculus';

			for my $pool_problem (@{ $problem_pool_info->{pool_problems} }) {
				push(
					@pool_problems_from_file,
					{
						%$pool_problem,
						course_name => $course_info->{course_name},
						pool_name   => $problem_pool_info->{pool_name}
					}
				);
			}
		}
	}
	@problem_pools_from_file = sort { $a->{pool_name} cmp $b->{pool_name} } @problem_pools_from_file;

	# FIXME: the getAllProblemPools method should not exist and should not be tested.
	# Why do you think these "get all" methods are a good idea?
	my @problem_pools_from_db = $problem_pool_rs->getAllProblemPools();
	@problem_pools_from_db = sort { $a->{pool_name} cmp $b->{pool_name} } @problem_pools_from_db;
	for my $pool (@problem_pools_from_db) {
		removeIDs($pool);
	}
	is(\@problem_pools_from_db, \@problem_pools_from_file, 'getAllProblemPools: find all problem pools');

	# Get all precalculus problem pools.
	my @precalc_pools = $problem_pool_rs->getProblemPools(info => { course_name => 'Precalculus' });
	for my $pool (@precalc_pools) {
		removeIDs($pool);
		$pool->{course_name} = 'Precalculus';
	}
	is(\@precalc_pools, \@precalc_pools_from_file, 'getProblemPools: get all problem pools from a single course');

	# Get a problem pool
	my $pool_to_fetch = $problem_pools_from_file[0];

	my $fetched_pool = $problem_pool_rs->getProblemPool(info => $pool_to_fetch);
	removeIDs($fetched_pool);
	$fetched_pool->{course_name} = $problem_pools_from_file[0]->{course_name};

	is($fetched_pool, $pool_to_fetch, 'getProblemPool: get a single pool from a course');

	# Try to get a problem pool from a course that doesn't exist.
	is(
		dies {
			$problem_pool_rs->getProblemPool(
				info => { course_name => 'not existent course', pool_name => 'adding fractions' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'getProblemPool: get a problem pool from a non-existent course'
	);

	# Try to get a problem pool from a course, but the pool doesn't exist.
	is(
		dies {
			$problem_pool_rs->getProblemPool(
				info => { course_name => 'Arithmetic', pool_name => 'non_existent_pool' });
		},
		check_isa('DB::Exception::PoolNotInCourse'),
		'getProblemPool: get a problem pool from a non-existent course'
	);

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

	is($pool2, { pool_name => $pool_name }, 'addProblemPool: add a new problem pool to a course');

	# Try to add a pool that already exists.
	is(
		dies {
			$problem_pool_rs->addProblemPool(
				params => { course_name => 'Arithmetic', pool_name => 'adding fractions' });
		},
		check_isa('DB::Exception::PoolAlreadyInCourse'),
		'addProblemPool: pool already exists'
	);

	# Try to add a pool with an invalid field.
	is(
		dies {
			$problem_pool_rs->addProblemPool(
				params => { course_name => 'Arithmetic', pool_name => 'dividing fractions', other_field => 'XXX' });
		},
		check_isa('DBIx::Class::Exception'),
		'addProblemPool: add a pool with non-valid field'
	);

	# Update an existing problem pool.
	my $updated_pool = { pool_name => 'subtracting fractions with like denominators', };

	my $updated_pool_from_db = $problem_pool_rs->updateProblemPool(
		info   => { course_name => 'Arithmetic', pool_name => 'subtracting fractions' },
		params => $updated_pool
	);
	$updated_pool_from_db->{course_name} = 'Arithmetic';

	removeIDs($updated_pool_from_db);
	$updated_pool->{course_name} = 'Arithmetic';

	is($updated_pool_from_db, $updated_pool, 'updateProblemPool: update the name of a problem pool');

	# TODO: Try to update a pool that doesn't exist.

	# Try to get a problem pool from a course that doesn't exist.
	is(
		dies {
			$problem_pool_rs->updateProblemPool(
				info  => { course_name => 'non_existent_course', pool_name => 'XXXX' },
				parms => $updated_pool
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'udpateProblemPool: update a problem pool from a non-existent course'
	);

	# Try to get a non-existent problem pool from a course.
	is(
		dies {
			$problem_pool_rs->updateProblemPool(
				info   => { course_name => 'Arithmetic', pool_name => 'non_existent_pool' },
				params => $updated_pool
			);
		},
		check_isa('DB::Exception::PoolNotInCourse'),
		'updateProblemPool: update a problem pool from a non-existent course'
	);

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

	is(
		$prob2->{library_id},
		$pool_problem2->{library_id},
		'getPoolProblem: get a single problem from a problem pool'
	);

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
	my @lib_ids = map  { $_->{params}{library_id} } @probs3;
	my @arr     = grep { $_ == $random_prob->{params}{library_id} } @lib_ids;

	ok(scalar(@arr) == 1, 'getPoolProblem: get a random problem from a problem pool');

	# Add a Problem to a pool.
	my $prob_to_add->{params} = { library_id => 8332 };
	my $added_problem = $problem_pool_rs->addProblemToPool(params => { %$updated_pool, %$prob_to_add });

	is(
		$prob_to_add->{params}{library_id},
		$added_problem->{params}{library_id},
		'addProblemToPool: adding a problem to an existing pool.'
	);

	# Check that adding a problem to a non-existence course fails.
	is(
		dies {
			$problem_pool_rs->addProblemToPool(
				params => { course_name => 'non_existing_course', pool_name => 'adding fractions', %$prob_to_add });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'addProblemToPool: try to add to a nonexisting course'
	);

	# Check that adding a problem to a non-existence pool fails.
	is(
		dies {
			$problem_pool_rs->addProblemToPool(
				params => {
					course_name => $updated_pool->{course_name},
					pool_name   => 'non_existent_pool_name',
					%$prob_to_add
				}
			);
		},
		check_isa('DB::Exception::PoolNotInCourse'),
		'addProblemToPool: try to add to a nonexisting pool'
	);

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
		$updated_pool_problem->{params}{library_id},
		'updatePoolProblem: update an existing problem in an existing pool.'
	);

	# Check that updating a problem to a non-existence course fails.
	is(
		dies {
			$problem_pool_rs->updatePoolProblem(
				info => {
					course_name     => 'non_existing_course',
					pool_name       => 'adding fractions',
					pool_problem_id => $added_problem->{pool_problem_id}
				},
				params => { params => { library_id => $updated_library_id } }
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'updatePoolProblem: try to update a nonexisting course'
	);

	# Check that updating a problem to a non-existence course fails.
	is(
		dies {
			$problem_pool_rs->updatePoolProblem(
				info => {
					course_name     => $updated_pool->{course_name},
					pool_name       => 'non_existent_pool_name',
					pool_problem_id => $added_problem->{pool_problem_id}
				},
				params => { library_id => $updated_library_id }
			);
		},
		check_isa('DB::Exception::PoolNotInCourse'),
		'updatePoolProblem: try to update  a nonexisting pool'
	);

	# Check that updating a problem to a non-existing problem fails.
	is(
		dies {
			$problem_pool_rs->updatePoolProblem(
				info => {
					course_name     => $updated_pool->{course_name},
					pool_name       => $updated_pool->{pool_name},
					pool_problem_id => -999
				},
				params => { library_id => $updated_library_id }
			);
		},
		check_isa('DB::Exception::PoolProblemNotInPool'),
		'updatePoolProblem: try to update a nonexisting problem'
	);

	# Delete a problem pool
	my $pool_to_delete = $problem_pool_rs->deleteProblemPool(info => $updated_pool);
	removeIDs($pool_to_delete);
	$pool_to_delete->{course_name} = 'Arithmetic';
	is($pool_to_delete, $updated_pool, 'deleteProblemPool: delete an existing problem pool');
};

done_testing;

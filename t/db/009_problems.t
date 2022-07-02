#!/usr/bin/env perl

# This tests the basic database CRUD functions of problems.

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Test::More;
use Test::Exception;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;
use DB::Utils qw/updateAllFields/;

# Load the database
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $problem_rs     = $schema->resultset('SetProblem');
my $problem_set_rs = $schema->resultset('ProblemSet');

# Load all problems from the CVS files.
my @problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/problems.csv");

# Filter out precalc problems
my @precalc_problems = grep { $_->{course_name} eq 'Precalculus' } @problems_from_csv;

# Filter out 'HW #1'
my @precalc_problems1 = grep { $_->{set_name} eq 'HW #1' } @precalc_problems;

for my $problem (@problems_from_csv) {
	delete $problem->{course_name};
}

my @all_problems = map { clone($_) } @problems_from_csv;

my @problems_from_db = $problem_rs->getGlobalProblems;
for my $problem (@problems_from_db) {
	removeIDs($problem);
}

is_deeply(\@all_problems, \@problems_from_db, 'getGlobalProblems: get all problems');

# Get all problems from one course.
my @precalc_problems_from_db = $problem_rs->getProblems(info => { course_name => 'Precalculus' });
for my $problem (@precalc_problems_from_db) {
	removeIDs($problem);
}

# Try to get all problems from a non existent course

throws_ok {
	$problem_rs->getProblems(
		info => {
			course_name => 'non existent course'
		}
	);
}
'DB::Exception::CourseNotFound', 'getProblems: non-existent course';

# Try to get all problems from a non-existent set_id

throws_ok {
	$problem_rs->getProblems(
		info => {
			course_id => 999999
		}
	);
}
'DB::Exception::CourseNotFound', 'getProblems: non-existent course_id';

for my $problem (@precalc_problems) {
	delete $problem->{set_name};
}

is_deeply(\@precalc_problems, \@precalc_problems_from_db, 'getSetProblems: get all problems from one course');

# Get all problems in one course from one set.
my @set_problems1 = $problem_rs->getSetProblems(info => { course_name => 'Precalculus', set_name => 'HW #1' });

for my $problem (@set_problems1) {
	removeIDs($problem);
}

is_deeply(\@precalc_problems1, \@set_problems1, 'getSetProblems: get all problems from one set');

# Try to get problems from a non-existing course.
throws_ok {
	$problem_rs->getSetProblems(info => { course_name => 'non_existing_course', set_name => 'HW #1' });
}
'DB::Exception::CourseNotFound', 'getSetProblems: get problems from non-existing course';

# Try to get problems from a non-existing set.
throws_ok {
	$problem_rs->getSetProblems(info => { course_name => 'Precalculus', set_name => 'HW #999' });
}
'DB::Exception::SetNotInCourse', 'getSetProblems: get problems from non-existing set';

# Get a single problem from a course.
my $set_problem = $problem_rs->getSetProblem(
	info => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_number => $problems_from_csv[0]->{problem_number}
	}
);
removeIDs($set_problem);

my $expected_problem = { %{ $problems_from_csv[0] } };    # Copy the first problem
delete $expected_problem->{set_name};
delete $expected_problem->{course_name};

is_deeply($expected_problem, $set_problem, 'getSetProblem: get a single problem from a set in a given course');

# Add a problem to an existing set.
my $new_problem = {
	problem_number => 4,
	problem_params => {
		library_id => 13245,
		weight     => 1
	}
};

my $prob1 = $problem_rs->addSetProblem(
	params => {
		course_name => 'Precalculus',
		set_name    => 'HW #1',
		%$new_problem
	}
);

my $prob_id = $prob1->{set_problem_id};
removeIDs($prob1);

is_deeply($new_problem, $prob1, 'addSetProblem: add a valid problem to a set');

# Add a problem and make sure the problem number is working.
# Determine the largest current problem number.

my @hw1_probs = $problem_rs->getSetProblems(
	info => {
		course_name => 'Precalculus',
		set_name    => 'HW #1'
	}
);

my @prob_nums = map { $_->{problem_number} } @hw1_probs;
my $max       = $prob_nums[0];
for my $i (1 .. $#prob_nums) { $max = $prob_nums[$i] if $prob_nums[$i] > $max; }

my $prob2_from_db = $problem_rs->addSetProblem(
	params => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_params => { file_path => 'path/to/problem.pg' }
	}
);
removeIDs($prob2_from_db);

my $prob2 = {
	'problem_params' => {
		'file_path' => 'path/to/problem.pg',
		'weight'    => 1
	},
	'problem_number' => $max + 1,
};

is_deeply($prob2, $prob2_from_db, 'addSetProblem: add a set problem and ensure the problem number is correct.');

# Try to add a problem to a non-existent course
throws_ok {
	$problem_rs->addSetProblem(
		params => {
			course_name => 'Non existent course',
			set_name    => 'HW #1'
		}
	);
}
'DB::Exception::CourseNotFound', 'addSetProblem: try to add a problem to a non-existent course';

# Try to add a problem to a non-existent course_id
throws_ok {
	$problem_rs->addSetProblem(
		params => {
			course_id => 999999,
			set_name  => 'HW #1'
		}
	);
}
'DB::Exception::CourseNotFound', 'addSetProblem: try to add a problem to a non-existent course_id';

# Try to add a problem to a non-existent set
throws_ok {
	$problem_rs->addSetProblem(
		params => {
			course_name => 'Precalculus',
			set_name    => 'HW #99999'
		}
	);
}
'DB::Exception::SetNotInCourse', 'addSetProblem: try to add a problem to a non-existent set';

# Try to add a problem to a non-existent set
throws_ok {
	$problem_rs->addSetProblem(
		params => {
			course_name => 'Precalculus',
			set_id      => 999999
		}
	);
}
'DB::Exception::SetNotInCourse', 'addSetProblem: try to add a problem to a non-existent set_id';

# Try to add a problem without information about the file_path, library_id or problem_pool_id
throws_ok {
	$problem_rs->addSetProblem(
		params => {
			course_name    => 'Precalculus',
			set_name       => 'HW #1',
			problem_params => {}
		}
	);
}
'DB::Exception::ParametersNeeded', "addSetProblem: try to add a problem without information about the file_path, etc.";

# Note: we may want to not have the following in the future, but currently its okay.
# Try to add a problem with both information about the file_path, and library_id .

my $set_prob_params2 = {
	course_name    => 'Precalculus',
	set_name       => 'HW #1',
	problem_params => {
		file_path  => 'this_is_a_path',
		library_id => 123,
		weight     => 1
	}
};

my $set_problem2 = $problem_rs->addSetProblem(params => $set_prob_params2);
# Make a copy to delete later.
my $set_problem_to_delete = clone $set_problem2;
delete $set_prob_params2->{course_name};
delete $set_prob_params2->{set_name};

removeIDs($set_problem2);
delete $set_problem2->{problem_number};

is_deeply($set_problem2, $set_prob_params2, 'addSetProblem: adding a problem with both file_path and library_id');

# Update a problem
my $updated_params = {
	problem_number => 99,
	problem_params => {
		weight => 2
	}
};

my $all_params      = updateAllFields($new_problem, $updated_params);
my $updated_problem = $problem_rs->updateSetProblem(
	info => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		set_problem_id => $prob_id
	},
	params => $updated_params
);
removeIDs($updated_problem);

is_deeply($all_params, $updated_problem, 'updateProblem: update a problem');

# Try to update a problem in a non-existent course
throws_ok {
	$problem_rs->updateSetProblem(
		info => {
			course_name => 'Non existent course',
			set_name    => 'HW #1'
		}
	);
}
'DB::Exception::CourseNotFound', 'updateSetProblem: try to update a problem to a non-existent course';

# Try to update a problem to with a non-existent course_id
throws_ok {
	$problem_rs->updateSetProblem(
		info => {
			course_id => 999999,
			set_name  => 'HW #1'
		}
	);
}
'DB::Exception::CourseNotFound', 'updateSetProblem: try to update a problem to a non-existent course_id';

# Try to update a problem to a non-existent set
throws_ok {
	$problem_rs->updateSetProblem(
		info => {
			course_name => 'Precalculus',
			set_name    => 'HW #99999'
		}
	);
}
'DB::Exception::SetNotInCourse', 'updateSetProblem: try to update a problem to a non-existent set';

# Try to update a problem to a non-existent set_id
throws_ok {
	$problem_rs->updateSetProblem(
		info => {
			course_name => 'Precalculus',
			set_id      => 999999
		}
	);
}
'DB::Exception::SetNotInCourse', 'updateSetProblem: try to update a problem to a non-existent set_id';

# Try to update a problem with a negative problem number.
throws_ok {
	$problem_rs->updateSetProblem(
		info => {
			course_name    => 'Precalculus',
			set_name       => 'HW #1',
			problem_number => 1,
		},
		params => {
			problem_number => -9
		}
	);
}
'DB::Exception::InvalidParameter',
	'updateSetProblem: try to update a problem with a non positive integer problem_number';

# Try to update a problem without information about the file_path, library_id or problem_pool_id
throws_ok {
	$problem_rs->updateSetProblem(
		params => {
			course_name    => 'Precalculus',
			set_name       => 'HW #1',
			problem_params => {
				file_path  => 'this_is_a_path',
				library_id => 123
			}
		}
	);
}
'DB::Exception::ParametersNeeded', 'updateSetProblem: try to add a problem with too much library info';

# Delete a problem from a set
my $deleted_problem = $problem_rs->deleteSetProblem(
	info => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_number => 99,
	}
);
removeIDs($deleted_problem);

is_deeply($updated_problem, $deleted_problem, 'deleteSetProblem: delete one problem in an existing set.');

my $deleted_problem2 = $problem_rs->deleteSetProblem(
	info => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_number => $set_problem_to_delete->{problem_number},
	}
);
is_deeply($deleted_problem2, $set_problem_to_delete, 'deleteSetProblem: delete another problem.');

my $deleted_problem3 = $problem_rs->deleteSetProblem(
	info => {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_number => $prob2->{problem_number}
	}
);
removeIDs($deleted_problem3);
is_deeply($deleted_problem3, $prob2, 'deleteSetProblem: delete another problem.');

# Make sure the set_problem table is returned to its orginal state.
@problems_from_db = $problem_rs->getGlobalProblems;
for my $problem (@problems_from_db) {
	removeIDs($problem);
}

is_deeply(\@all_problems, \@problems_from_db, 'The set_problems table is returned to its original state.');

# Ensure that the set_problems table is restored.
@problems_from_db = $problem_rs->getGlobalProblems;
for my $problem (@problems_from_db) {
	removeIDs($problem);
}

is_deeply(\@all_problems, \@problems_from_db, 'check: Ensure that the set_problems table is restored.');

done_testing;

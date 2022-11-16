#!/usr/bin/env perl

# This tests the basic database CRUD functions of problems.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json/;
use Clone qw/clone/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/addCourses addSets addProblems/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs/;
use DB::Utils qw/updateAllFields/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'course users' => sub ($schema) {
	# Add the neccessary sample data to the database.
	addCourses($schema, $ww3_dir);
	addSets($schema, $ww3_dir);
	addProblems($schema, $ww3_dir);

	my $problem_rs = $schema->resultset('SetProblem');

	# Load all problems from the the JSON file.
	my $course_set_problems = decode_json($ww3_dir->child('t/db/sample_data/problems.json')->slurp);
	my @all_problems;
	my @precalc_problems;
	my @precalc_problems1;
	for my $course_info (@$course_set_problems) {
		for my $set_info (@{ $course_info->{sets} }) {
			for (@{ $set_info->{problems} }) {
				push(@all_problems, { %$_, set_name => $set_info->{set_name} });

				# Separate out precalculus problems.
				push(@precalc_problems, $_) if $course_info->{course_name} eq 'Precalculus';

				# Separate out precalculus 'HW #1' problems.
				push(@precalc_problems1, $_)
					if $course_info->{course_name} eq 'Precalculus' && $set_info->{set_name} eq 'HW #1';
			}
		}
	}

	# FIXME:  The getGlobalProblems method should not exist and should not be tested.
	my @problems_from_db = $problem_rs->getGlobalProblems;
	for my $problem (@problems_from_db) {
		removeIDs($problem);
	}
	is(\@problems_from_db, \@all_problems, 'getGlobalProblems: get all problems');

	# FIXME: The getProblems method should not exist and should not be tested.
	# Get all problems from one course.
	my @precalc_problems_from_db = $problem_rs->getProblems(info => { course_name => 'Precalculus' });
	for my $problem (@precalc_problems_from_db) {
		removeIDs($problem);
	}
	is(\@precalc_problems_from_db, \@precalc_problems, 'getSetProblems: get all problems from one course');

	# Try to get all problems from a non existent course
	is(
		dies { $problem_rs->getProblems(info => { course_name => 'non existent course' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'getProblems: non-existent course'
	);

	# Try to get all problems from a non-existent set_id
	is(
		dies { $problem_rs->getProblems(info => { course_id => 999999 }); },
		check_isa('DB::Exception::CourseNotFound'),
		'getProblems: non-existent course_id'
	);

	# Get all problems in one course from one set.
	my @set_problems1 = $problem_rs->getSetProblems(info => { course_name => 'Precalculus', set_name => 'HW #1' });

	for my $problem (@set_problems1) {
		removeIDs($problem);
	}

	is(\@set_problems1, \@precalc_problems1, 'getSetProblems: get all problems from one set');

	# Try to get set problems from a non-existing course.
	is(
		dies {
			$problem_rs->getSetProblems(info => { course_name => 'non_existing_course', set_name => 'HW #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'getSetProblems: get problems from non-existing course'
	);

	# Try to get set problems from a non-existing set.
	is(
		dies {
			$problem_rs->getSetProblems(info => { course_name => 'Precalculus', set_name => 'HW #999' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'getSetProblems: get problems from non-existing set'
	);

	# Get a single problem from a course.
	my $set_problem = $problem_rs->getSetProblem(
		info => {
			course_name    => $course_set_problems->[0]{course_name},
			set_name       => $course_set_problems->[0]{sets}[0]{set_name},
			problem_number => $course_set_problems->[0]{sets}[0]{problems}[0]{problem_number}
		}
	);
	removeIDs($set_problem);

	my $expected_problem = { %{ $course_set_problems->[0]{sets}[0]{problems}[0] } };    # Copy the first problem

	is($set_problem, $expected_problem, 'getSetProblem: get a single problem from a set in a given course');

	# Add a problem to an existing set.
	my $new_problem = { problem_number => 4, problem_params => { library_id => 13245, weight => 1 } };

	my $prob1 =
		$problem_rs->addSetProblem(params => { course_name => 'Precalculus', set_name => 'HW #1', %$new_problem });

	my $prob_id = $prob1->{set_problem_id};
	removeIDs($prob1);

	is($prob1, $new_problem, 'addSetProblem: add a valid problem to a set');

	# Add a problem and make sure the problem number is working.
	# Determine the largest current problem number.

	my @hw1_probs = $problem_rs->getSetProblems(info => { course_name => 'Precalculus', set_name => 'HW #1' });

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
		'problem_params' => { 'file_path' => 'path/to/problem.pg', 'weight' => 1 },
		'problem_number' => $max + 1,
	};

	is($prob2_from_db, $prob2, 'addSetProblem: add a set problem and ensure the problem number is correct.');

	# Try to add a problem to a non-existent course
	is(
		dies {
			$problem_rs->addSetProblem(params => { course_name => 'Non existent course', set_name => 'HW #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'addSetProblem: try to add a problem to a non-existent course'
	);

	# Try to add a problem to a non-existent course_id
	is(
		dies { $problem_rs->addSetProblem(params => { course_id => 999999, set_name => 'HW #1' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'addSetProblem: try to add a problem to a non-existent course_id'
	);

	# Try to add a problem to a non-existent set
	is(
		dies {
			$problem_rs->addSetProblem(params => { course_name => 'Precalculus', set_name => 'HW #99999' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'addSetProblem: try to add a problem to a non-existent set'
	);

	# Try to add a problem to a non-existent set
	is(
		dies { $problem_rs->addSetProblem(params => { course_name => 'Precalculus', set_id => 999999 }); },
		check_isa('DB::Exception::SetNotInCourse'),
		'addSetProblem: try to add a problem to a non-existent set_id'
	);

	# Try to add a problem without information about the file_path, library_id or problem_pool_id
	is(
		dies {
			$problem_rs->addSetProblem(
				params => { course_name => 'Precalculus', set_name => 'HW #1', problem_params => {} });
		},
		check_isa('DB::Exception::FieldsNeeded'),
		"addSetProblem: try to add a problem without information about the file_path, etc."
	);

	# Note: we may want to not have the following in the future, but currently its okay.
	# Try to add a problem with both information about the file_path, and library_id .

	my $set_prob_params2 = {
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_params => { file_path => 'this_is_a_path', library_id => 123, weight => 1 }
	};

	my $set_problem2 = $problem_rs->addSetProblem(params => $set_prob_params2);
	# Make a copy to delete later.
	my $set_problem_to_delete = clone $set_problem2;
	delete $set_prob_params2->{course_name};
	delete $set_prob_params2->{set_name};

	removeIDs($set_problem2);
	delete $set_problem2->{problem_number};

	is($set_problem2, $set_prob_params2, 'addSetProblem: adding a problem with both file_path and library_id');

	# Update a problem
	my $updated_params = { problem_number => 99, problem_params => { weight => 2 } };

	my $all_params      = updateAllFields($new_problem, $updated_params);
	my $updated_problem = $problem_rs->updateSetProblem(
		info   => { course_name => 'Precalculus', set_name => 'HW #1', set_problem_id => $prob_id },
		params => $updated_params
	);
	removeIDs($updated_problem);

	is($updated_problem, $all_params, 'updateProblem: update a problem');

	# Try to update a problem in a non-existent course
	is(
		dies {
			$problem_rs->updateSetProblem(info => { course_name => 'Non existent course', set_name => 'HW #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'updateSetProblem: try to update a problem to a non-existent course'
	);

	# Try to update a problem to with a non-existent course_id
	is(
		dies { $problem_rs->updateSetProblem(info => { course_id => 999999, set_name => 'HW #1' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'updateSetProblem: try to update a problem to a non-existent course_id'
	);

	# Try to update a problem to a non-existent set
	is(
		dies {
			$problem_rs->updateSetProblem(info => { course_name => 'Precalculus', set_name => 'HW #99999' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'updateSetProblem: try to update a problem to a non-existent set'
	);

	# Try to update a problem to a non-existent set_id
	is(
		dies { $problem_rs->updateSetProblem(info => { course_name => 'Precalculus', set_id => 999999 }); },
		check_isa('DB::Exception::SetNotInCourse'),
		'updateSetProblem: try to update a problem to a non-existent set_id'
	);

	# Try to update a problem with a negative problem number.
	is(
		dies {
			$problem_rs->updateSetProblem(
				info   => { course_name    => 'Precalculus', set_name => 'HW #1', problem_number => 1, },
				params => { problem_number => -9 }
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'updateSetProblem: try to update a problem with a non positive integer problem_number'
	);

	# Try to update a problem without information about the file_path, library_id or problem_pool_id
	is(
		dies {
			$problem_rs->updateSetProblem(
				params => {
					course_name    => 'Precalculus',
					set_name       => 'HW #1',
					problem_params => { file_path => 'this_is_a_path', library_id => 123 }
				}
			);
		},
		check_isa('DB::Exception::ParametersNeeded'),
		'updateSetProblem: try to add a problem with too much library info'
	);

	# Delete a problem from a set
	my $deleted_problem =
		$problem_rs->deleteSetProblem(
			info => { course_name => 'Precalculus', set_name => 'HW #1', problem_number => 99 });
	removeIDs($deleted_problem);

	is($deleted_problem, $updated_problem, 'deleteSetProblem: delete one problem in an existing set.');

	my $deleted_problem2 = $problem_rs->deleteSetProblem(
		info => {
			course_name    => 'Precalculus',
			set_name       => 'HW #1',
			problem_number => $set_problem_to_delete->{problem_number},
		}
	);
	is($deleted_problem2, $set_problem_to_delete, 'deleteSetProblem: delete another problem.');
};

done_testing;

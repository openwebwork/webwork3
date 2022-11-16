#!/usr/bin/env perl

# This tests the basic database CRUD functions of attempts.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/loadPermissions addCourses addUsers addSets addProblems addUserSets addUserProblems/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'course users' => sub ($schema) {
	# Add the neccessary sample data to the database.
	loadPermissions($schema, $ww3_dir);
	addCourses($schema, $ww3_dir);
	addUsers($schema, $ww3_dir);
	addSets($schema, $ww3_dir);
	addProblems($schema, $ww3_dir);
	addUserSets($schema, $ww3_dir);
	addUserProblems($schema, $ww3_dir);

	# FIXME: This doesn't need all of the data above.  It needs 1 course, 1 set, 1 problem, 1 user, and 1 user problem.

	my $user_problem_rs = $schema->resultset('UserProblem');
	my $attempt_rs      = $schema->resultset('Attempt');

	# Add a few attempts for a given user problem.
	my $user_problem_info =
		{ course_name => 'Precalculus', username => 'homer', set_name => 'HW #2', problem_number => 3 };

	my $attempt_params1 = { scores => [ 0, 1, 1 ], answers => [ 'x', 'x^2', 'x^3' ], comments => {} };

	my $attempt1 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params1 });
	removeIDs($attempt1);

	is($attempt1, $attempt_params1, 'addAttempt: add an attempt');

	my $attempt_params2 = { scores => [ 0, 1, 1 ], answers => [ '2x', '3x^2', '4x^3' ], comments => {} };

	my $attempt2 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params2 });
	removeIDs($attempt2);
	is($attempt2, $attempt_params2, 'addAttempt: add another attempt');

	my $attempt_params3 = { scores => [ 0, 0, 0 ], answers => [ '-2x', '2x^2', '4x^3' ], comments => {} };

	my $attempt3 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params3 });
	removeIDs($attempt3);
	is($attempt3, $attempt_params3, 'addAttempt: add yet another attempt');

	my @all_attempts = $attempt_rs->getAttempts(info => $user_problem_info);
	for my $attempt (@all_attempts) {
		removeIDs($attempt);
	}

	is(
		\@all_attempts,
		[ $attempt_params1, $attempt_params2, $attempt_params3 ],
		"getAttempts: get attempts for a user problem;"
	);
};

done_testing;

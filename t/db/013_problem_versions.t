#!/usr/bin/env perl

# This tests the basic functions related to versioning in user sets.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json/;
use Clone qw/clone/;

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

	my $problem_rs      = $schema->resultset('SetProblem');
	my $user_problem_rs = $schema->resultset('UserProblem');

	# Load user problems from the JSON file.
	my $course_set_problem_user_problems =
		decode_json($ww3_dir->child('t/db/sample_data/user_problems.json')->slurp);
	my @user_problems_from_json;
	for my $course_info (@$course_set_problem_user_problems) {
		for my $set_info (@{ $course_info->{sets} }) {
			for my $problem_info (@{ $set_info->{problems} }) {
				for my $user_info (@{ $problem_info->{users} }) {
					$user_info->{user_problem}{course_name}    = $course_info->{course_name};
					$user_info->{user_problem}{set_name}       = $set_info->{set_name};
					$user_info->{user_problem}{problem_number} = $problem_info->{problem_number};
					$user_info->{user_problem}{username}       = $user_info->{username};
					$user_info->{user_problem}{status}          //= 1;
					$user_info->{user_problem}{problem_params}  //= {};
					$user_info->{user_problem}{problem_version} //= 1;
					push(@user_problems_from_json, $user_info->{user_problem});
				}
			}
		}
	}

	# Load all problems from the the JSON file.
	my $course_set_problems = decode_json($ww3_dir->child('t/db/sample_data/problems.json')->slurp);
	my @problems_from_json;
	for my $course_info (@$course_set_problems) {
		for my $set_info (@{ $course_info->{sets} }) {
			for my $problem_info (@{ $set_info->{problems} }) {
				$problem_info->{course_name} = $course_info->{course_name};
				$problem_info->{set_name}    = $set_info->{set_name};
				$problem_info->{status}          //= 1;
				$problem_info->{problem_version} //= 1;
				push(@problems_from_json, $problem_info);
			}
		}
	}

	my @merged_problems_from_json = ();
	for my $user_problem (@user_problems_from_json) {
		my $problem = clone(
			(
				grep {
					$_->{course_name} eq $user_problem->{course_name}
						&& $_->{set_name} eq $user_problem->{set_name}
						&& $_->{problem_number} == $user_problem->{problem_number}
				} @problems_from_json
			)[0]
		);

		# Override the following fields from user problems.
		for my $key (qw/seed status problem_version username/) {
			$problem->{$key} = $user_problem->{$key} if defined($user_problem->{$key});
		}
		# Override any parameters from user problems.
		for my $key (keys %{ $user_problem->{problem_params} }) {
			$problem->{problem_params}{$key} = $user_problem->{problem_params}{$key}
				if defined $problem->{problem_params}{$key};
		}
		push(@merged_problems_from_json, $problem);
	}
	# Get a user problem from a course

	my $user_problem_info = {
		username       => 'bart',
		course_name    => 'Precalculus',
		set_name       => 'HW #1',
		problem_number => 1
	};

	my $user_problem1 = $user_problem_rs->getUserProblem(info => $user_problem_info);
	removeIDs($user_problem1);
	delete $user_problem1->{set_visible} unless defined $user_problem1->{set_visible};

	# Check that it is the same as that from the JSON file

	my $user_problem1_from_json = clone(
		(
			grep {
				$_->{course_name} eq $user_problem_info->{course_name}
					&& $_->{set_name} eq $user_problem_info->{set_name}
					&& $_->{username} eq $user_problem_info->{username}
					&& $_->{problem_number} == $user_problem_info->{problem_number}
			} @user_problems_from_json
		)[0]
	);

	# the status needs be returned to a numerical value.
	$user_problem1->{status} += 0;

	is($user_problem1, $user_problem1_from_json, 'getUserProblem: get a single user problem from a course.');

	# Make a new user problem that has a problem_version of 2

	my $user_problem1_v2_params = clone $user_problem1;
	$user_problem1_v2_params->{problem_version} = 2;

	my $user_problem1_v2 =
		$user_problem_rs->addUserProblem(params => { %$user_problem_info, %$user_problem1_v2_params });
	removeIDs($user_problem1_v2);

	is($user_problem1_v2, $user_problem1_v2_params, "addUserProblem: add a user problem with version =2 ");

	# Make a new user set that has a  set_version of 3

	my $user_problem1_v3_params = clone $user_problem1;
	$user_problem1_v3_params->{problem_version} = 3;

	my $user_problem1_v3 =
		$user_problem_rs->addUserProblem(params => { %$user_problem_info, %$user_problem1_v3_params });
	removeIDs($user_problem1_v3);

	is($user_problem1_v3, $user_problem1_v3_params, "addUserProblem: add a user problem with version =3 ");

	my @all_user_problem_versions = $user_problem_rs->getUserProblemVersions(info => $user_problem_info);

	for my $user_problem (@all_user_problem_versions) {
		removeIDs($user_problem);
		$user_problem->{status} += 0;
	}

	is(
		\@all_user_problem_versions,
		[ $user_problem1, $user_problem1_v2, $user_problem1_v3 ],
		'getUserProblemVersions: get all versions of a user problem'
	);

	# clean up the created versioned user sets.

	my $user_problem_v2_to_delete = $user_problem_rs->deleteUserProblem(
		info => {
			course_name     => $user_problem1_v2_params->{course_name},
			set_name        => $user_problem1_v2_params->{set_name},
			username        => $user_problem1_v2_params->{username},
			problem_number  => $user_problem1_v2_params->{problem_number},
			problem_version => $user_problem1_v2_params->{problem_version}
		}
	);
	removeIDs($user_problem_v2_to_delete);
	$user_problem_v2_to_delete->{status} += 0;

	is($user_problem_v2_to_delete, $user_problem1_v2, 'deleteUserProblem: delete a versioned user problem');

	my $user_problem_v3_to_delete = $user_problem_rs->deleteUserProblem(
		info => {
			course_name     => $user_problem1_v3_params->{course_name},
			set_name        => $user_problem1_v3_params->{set_name},
			username        => $user_problem1_v3_params->{username},
			problem_number  => $user_problem1_v3_params->{problem_number},
			problem_version => $user_problem1_v3_params->{problem_version}
		}
	);
	removeIDs($user_problem_v3_to_delete);
	$user_problem_v3_to_delete->{status} += 0;

	is($user_problem_v3_to_delete, $user_problem1_v3, 'deleteUserProblem: delete another versioned user problem');
};

done_testing;

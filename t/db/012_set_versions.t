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

use BuildDB qw/loadPermissions addCourses addUsers addSets addUserSets/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs cleanUndef/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'course users' => sub ($schema) {
	# Add the neccessary sample data to the database.
	loadPermissions($schema, $ww3_dir);
	addCourses($schema, $ww3_dir);
	addUsers($schema, $ww3_dir);
	addSets($schema, $ww3_dir);
	addUserSets($schema, $ww3_dir);

	my $user_set_rs = $schema->resultset('UserSet');

	# Load HW sets from JSON file.
	my $course_hw_sets = decode_json($ww3_dir->child('t/db/sample_data/hw_sets.json')->slurp);
	my @hw_sets;
	for my $course_data (@$course_hw_sets) {
		for my $hw_set (@{ $course_data->{sets} }) {
			$hw_set->{set_type}    = 'HW';
			$hw_set->{course_name} = $course_data->{course_name};
			push(@hw_sets, $hw_set);
		}
	}

	# Load quiz sets from JSON file.
	my $course_quizzes = decode_json($ww3_dir->child('t/db/sample_data/quizzes.json')->slurp);
	my @quizzes;
	for my $course_data (@$course_quizzes) {
		for my $quiz (@{ $course_data->{sets} }) {
			$quiz->{set_type}    = 'QUIZ';
			$quiz->{course_name} = $course_data->{course_name};
			push(@quizzes, $quiz);
		}
	}

	# Load review sets from JSON file.
	my $course_review_sets = decode_json($ww3_dir->child('t/db/sample_data/review_sets.json')->slurp);
	my @review_sets;
	for my $course_data (@$course_review_sets) {
		for my $review_set (@{ $course_data->{sets} }) {
			$review_set->{set_type}    = 'REVIEW';
			$review_set->{course_name} = $course_data->{course_name};
			push(@review_sets, $review_set);
		}
	}

	my @all_problem_sets = (@hw_sets, @quizzes, @review_sets);

	my $course_set_users = decode_json($ww3_dir->child('t/db/sample_data/user_sets.json')->slurp);
	my @all_user_sets;
	for my $course_data (@$course_set_users) {
		for my $set_data (@{ $course_data->{sets} }) {
			for my $user_data (@{ $set_data->{users} }) {
				$user_data->{user_set}{course_name} = $course_data->{course_name};
				$user_data->{user_set}{set_name}    = $set_data->{set_name};
				$user_data->{user_set}{username}    = $user_data->{username};
				$user_data->{user_set}{set_version} //= 0;
				$user_data->{user_set}{set_dates}   //= {};
				$user_data->{user_set}{set_params}  //= {};
				$user_data->{user_set}{set_type} = (
					grep {
						$_->{course_name} eq $course_data->{course_name} && $_->{set_name} eq $set_data->{set_name}
					} @all_problem_sets
				)[0]{set_type};
				push(@all_user_sets, $user_data->{user_set});
			}
		}
	}

	for my $set (@all_user_sets) {
		$set->{set_version} = 0 unless defined($set->{set_version});
		# find the problem set type
		my $s =
			(grep { $_->{course_name} eq $set->{course_name} && $_->{set_name} eq $set->{set_name} } @all_problem_sets)
			[0];
		$set->{set_type}   = $s->{set_type};
		$set->{set_params} = {} unless defined $set->{set_params};
	}

	my @merged_user_sets = @{ clone(\@all_user_sets) };

	# Merge the sets

	for my $user_set (@merged_user_sets) {
		my $set = (grep { $_->{course_name} eq $user_set->{course_name} && $_->{set_name} eq $user_set->{set_name} }
				@all_problem_sets)[0];

		# override problem set dates with userset dates if exist
		my $dates = clone($set->{set_dates});
		for my $d (keys %{ $user_set->{set_dates} }) {
			$dates->{$d} = $user_set->{set_dates}{$d};
		}

		# Determine params and dates overrides
		my $params = clone($set->{set_params});
		for my $key (keys %{ $user_set->{set_params} }) {
			$params->{$key} = $user_set->{set_params}{$key};
		}

		$user_set->{set_params}  = $params;
		$user_set->{set_dates}   = $dates;
		$user_set->{set_version} = 0                   unless defined($user_set->{set_version});
		$user_set->{set_type}    = $set->{set_type}    unless defined($user_set->{set_type});
		$user_set->{set_visible} = $set->{set_visible} unless defined($user_set->{set_visible});
	}

	# Get a user set from a course

	my $user_set_info1 = {
		username    => 'bart',
		course_name => 'Precalculus',
		set_name    => 'HW #2'
	};

	my $user_set1 = $user_set_rs->getUserSet(info => $user_set_info1);
	removeIDs($user_set1);
	cleanUndef($user_set1);

	# Check that it is the same as that from the JSON file
	my $user_set1_from_json = (
		grep {
			$_->{course_name} eq $user_set_info1->{course_name}
				&& $_->{set_name} eq $user_set_info1->{set_name}
				&& $_->{username} eq $user_set_info1->{username}
		} @all_user_sets
	)[0];

	# Make a new user set that has a  set_version of 1

	is($user_set1, $user_set1_from_json, 'getUserSet: get a single user set from a course.');

	my $user_set1_v1_params = clone $user_set1;
	$user_set1_v1_params->{set_version} = 1;

	my $user_set1_v1 = $user_set_rs->addUserSet(params => { %$user_set_info1, %$user_set1_v1_params });
	removeIDs($user_set1_v1);
	cleanUndef($user_set1_v1);

	is($user_set1_v1, $user_set1_v1_params, "addUserSet: add a user set with version =1 ");

	# Make a new user set that has a  set_version of 2

	my $user_set1_v2_params = clone $user_set1_v1_params;
	$user_set1_v2_params->{set_version} = 2;

	my $user_set1_v2 = $user_set_rs->addUserSet(params => { %$user_set_info1, %$user_set1_v2_params });
	removeIDs($user_set1_v2);
	cleanUndef($user_set1_v2);

	is($user_set1_v2, $user_set1_v2_params, "addUserSet: add a user set with  version = 2.");

	my @all_user_set_versions = $user_set_rs->getUserSetVersions(info => $user_set_info1);
	for my $user_set (@all_user_set_versions) {
		removeIDs($user_set);
		cleanUndef($user_set);
	}

	is(
		\@all_user_set_versions,
		[ $user_set1, $user_set1_v1, $user_set1_v2 ],
		'getUserSetVersions: get all versions of a user set.'
	);

	# clean up the created versioned user sets.

	my $user_set_v1_to_delete = $user_set_rs->deleteUserSet(
		info => {
			course_name => $user_set1_v1_params->{course_name},
			set_name    => $user_set1_v1_params->{set_name},
			username    => $user_set1_v1_params->{username},
			set_version => $user_set1_v1_params->{set_version}
		}
	);

	removeIDs($user_set_v1_to_delete);
	cleanUndef($user_set_v1_to_delete);
	is($user_set_v1_to_delete, $user_set1_v1, 'deleteUserSet: delete user set with set_version = 1');

	my $user_set_v2_to_delete = $user_set_rs->deleteUserSet(
		info => {
			course_name => $user_set1_v2_params->{course_name},
			set_name    => $user_set1_v2_params->{set_name},
			username    => $user_set1_v2_params->{username},
			set_version => $user_set1_v2_params->{set_version}
		}
	);

	removeIDs($user_set_v2_to_delete);
	cleanUndef($user_set_v2_to_delete);
	is($user_set_v2_to_delete, $user_set1_v2, 'deleteUserSet: delete a versioned user set');
};

done_testing;

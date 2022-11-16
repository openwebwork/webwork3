#!/usr/bin/env perl

# This tests the basic database CRUD functions of user problems.

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

	# User problem sort function.
	sub user_prob_sort_fcn {
		return
			$a->{course_name} cmp $b->{course_name}
			|| $a->{set_name} cmp $b->{set_name}
			|| $a->{username} cmp $b->{username}
			|| $a->{problem_number} <=> $b->{problem_number};
	}

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

	# Sort before comparing.
	@user_problems_from_json = sort user_prob_sort_fcn @user_problems_from_json;

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

	# FIXME:  the getAllUserProblems method should not exist and should not be tested.
	# Get all user problems.
	my @all_user_problems_from_db = $user_problem_rs->getAllUserProblems();
	for my $user_problem (@all_user_problems_from_db) {
		removeIDs($user_problem);
		delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
	}

	@all_user_problems_from_db = sort user_prob_sort_fcn @all_user_problems_from_db;

	# For comparision, from the database needs to be a number.
	$_->{status} = 0 + $_->{status} for (@all_user_problems_from_db);

	is(\@all_user_problems_from_db, \@user_problems_from_json,
		'getAllUserProblems: fetch all user problems from the DB.');

	# Get merged user problems.
	my @merged_problems_from_db = $user_problem_rs->getAllUserProblems(merged => 1);
	for my $merged_problem (@merged_problems_from_db) {
		removeIDs($merged_problem);
	}

	# For comparision, from the database needs to be a number.
	$_->{status} = 0 + $_->{status} for (@merged_problems_from_db);

	@merged_problems_from_db = sort user_prob_sort_fcn @merged_problems_from_db;

	# For comparision, from the database needs to be a number.
	$_->{status} = 0 + $_->{status} for (@merged_problems_from_db);

	@merged_problems_from_db = sort user_prob_sort_fcn @merged_problems_from_db;

	is(\@merged_problems_from_db, \@merged_problems_from_json, 'getAllUserProblems: fetch all merged problems');

	# Get user problems from one course.
	my @precalc_user_problems = grep { $_->{course_name} eq 'Precalculus' } @user_problems_from_json;

	my @precalc_user_problems_from_db = $user_problem_rs->getUserProblems(info => { course_name => 'Precalculus' });
	for my $user_problem (@precalc_user_problems_from_db) {
		removeIDs($user_problem);
		delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
		$user_problem->{status} += 0;
	}

	@precalc_user_problems_from_db = sort user_prob_sort_fcn @precalc_user_problems_from_db;

	is(\@precalc_user_problems_from_db,
		\@precalc_user_problems, 'getUserProblems: get user problems from a single course.');

	# Get merged problems from one course.
	my @precalc_merged_problems = grep { $_->{course_name} eq 'Precalculus' } @merged_problems_from_json;

	my @precalc_merged_problems_from_db = $user_problem_rs->getUserProblems(
		info   => { course_name => 'Precalculus' },
		merged => 1
	);
	for my $merged_problem (@precalc_merged_problems_from_db) {
		removeIDs($merged_problem);
		$merged_problem->{status} += 0;
	}

	@precalc_merged_problems         = sort user_prob_sort_fcn @precalc_merged_problems;
	@precalc_merged_problems_from_db = sort user_prob_sort_fcn @precalc_merged_problems_from_db;

	is(\@precalc_merged_problems_from_db,
		\@precalc_merged_problems, 'getUserProblems: get merged problems from a single course.');

	# Get a single user problem.
	my $user_problem = $user_problem_rs->getUserProblem(
		info => { course_name => 'Precalculus', username => 'homer', set_name => 'HW #2', problem_number => 3 });
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
	$user_problem->{status} += 0;

	my $user_problem_from_json = clone(
		(
			grep {
				$_->{course_name} eq 'Precalculus'
					&& $_->{username} eq 'homer'
					&& $_->{set_name} eq 'HW #2'
					&& $_->{problem_number} == 3
			} @precalc_user_problems
		)[0]
	);

	is($user_problem, $user_problem_from_json, 'getUserProblem: get a single user problem');

	# Get a user problem from a course that doesn't exist.
	is(
		dies {
			$user_problem_rs->getUserProblem(
				info => {
					course_name    => 'course doesn\'t exist',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'getUserProblem: attempt to get a user problem from a nonexistent course'
	);

	# Get a user problem from a user that doesn't exist.
	is(
		dies {
			$user_problem_rs->getUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'non_existent_user',
					set_name       => 'HW #1',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::UserNotFound'),
		'getUserProblem: attempt to get a user problem from a nonexistent user'
	);

	# Get a user problem from a set that doesn't exist.
	is(
		dies {
			$user_problem_rs->getUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #99',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'getUserProblem: attempt to get a user problem from a nonexistent set'
	);

	# Get a user problem from a problem that doesn't exist.
	is(
		dies {
			$user_problem_rs->getUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 99
				}
			);
		},
		check_isa('DB::Exception::SetProblemNotFound'),
		'getUserProblem: attempt to get a user problem from a nonexistent problem'
	);

	# Add a UserProblem to the database.
	my $problem_info1 =
		{ course_name => 'Precalculus', set_name => 'HW #4', username => 'ned', problem_number => 1 };

	my $user_problem1 = $user_problem_rs->addUserProblem(params => { %$problem_info1, seed => 7329 });
	removeIDs($user_problem1);
	$problem_info1->{seed}            = 7329;
	$problem_info1->{status}          = 0;
	$problem_info1->{problem_params}  = {};
	$problem_info1->{problem_version} = 1;

	is($user_problem1, $problem_info1, 'addUserProblem: add a single user problem');

	# Add a user problem and get back a merged problem.
	my $problem_info2 =
		{ course_name => 'Precalculus', set_name => 'HW #4', username => 'ned', problem_number => 2 };

	my $user_problem2 = $user_problem_rs->addUserProblem(
		params => { %$problem_info2, seed => 7329, problem_params => { weight => 2 } },
		merged => 1
	);

	removeIDs($user_problem2);

	my $problem2 = clone(
		(
			grep {
				$_->{course_name} eq $problem_info2->{course_name}
					&& $_->{set_name} eq $problem_info2->{set_name}
					&& $_->{problem_number} eq $problem_info2->{problem_number}
			} @problems_from_json
		)[0]
	);

	# Merge the two problems.
	for my $key (qw/username seed status problem_version/) {
		$problem2->{$key} = $user_problem2->{$key} if defined $user_problem2->{$key};
	}
	$problem2->{problem_params}{weight} = 2;

	is($user_problem2, $problem2, 'addUserProblem: add a user problem and return a merged problem');

	# Attempt to add a UserProblem to a non-existent course.
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'course doesn\'t exist',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'addUserProblem: attempt to add a user problem to a nonexistent course'
	);

	# Attempt to add a UserProblem for a non-existent problem set.
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #999',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'addUserProblem: attempt to add a user problem for a non-existent problem set'
	);

	# Attempt to add a UserProblem for a non-existent user.
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					username       => 'non_existent_user',
					set_name       => 'HW #1',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::UserNotFound'),
		'addUserProblem: attempt to add a user problem for a non-existent user'
	);

	# Attempt to add a UserProblem for a non-existent problem.
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 999
				}
			);
		},
		check_isa('DB::Exception::SetProblemNotFound'),
		'addUserProblem: attempt to add a user problem for a non-existent problem'
	);

	# Attempt to add a UserProblem that already exists
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 1
				}
			);
		},
		check_isa('DB::Exception::UserProblemExists'),
		'addUserProblem: attempt to add a user problem that already exists'
	);

	# Try to add a UserProblem with a bad seed :) .
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 3,
					seed           => -1234
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addUserProblem: attempt to add a user problem with a bad seed'
	);

	# Attempt to add a new User Problem with a non existent field
	is(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name        => 'Precalculus',
					set_name           => 'HW #4',
					username           => 'ned',
					problem_number     => 3,
					non_existent_field => 1
				}
			);
		},
		check_isa('DBIx::Class::Exception'),
		'addUserProblem: attempt to add a user problem with a non existent field'
	);

	# Attempt to add a new User Problem with a non existent field
	like(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name        => 'Precalculus',
					set_name           => 'HW #4',
					username           => 'ned',
					problem_number     => 3,
					non_existent_field => 1
				}
			);
		},
		qr/No such column 'non_existent_field'/,
		'addUserProblem: attempt to add a user problem with a non existent field'
	);

	# Attempt to add a new User Problem with invalid library id
	like(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 3,
					problem_params => { library_id => -1234 }
				}
			);
		},
		qr/library_id is not valid/,
		'addUserProblem: attempt to add a user problem with with invalid library id'
	);

	# Attempt to add a new User Problem with a bad problem weight
	like(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 3,
					problem_params => { weight => -1 }
				}
			);
		},
		qr/weight is not valid/,
		'addUserProblem: attempt to add a user problem with a bad problem weight'
	);

	# Attempt to add a new User Problem with a invalid problem_pool_id
	like(
		dies {
			$user_problem_rs->addUserProblem(
				params => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 3,
					problem_params => { problem_pool_id => 'fred' }
				}
			);
		},
		qr/problem_pool_id is not valid/,
		'addUserProblem: attempt to add a user problem with a bad problem_pool_id'
	);

	# update a user problem and return as a user problem
	my $updated_problem1 = $user_problem_rs->updateUserProblem(info => $problem_info1, params => { seed => 4567 });
	removeIDs($updated_problem1);
	# the status needs be returned to a numerical value.
	$updated_problem1->{status} += 0;

	delete $updated_problem1->{problem_version} unless defined $updated_problem1->{problem_version};
	$user_problem1->{seed} = 4567;

	is($updated_problem1, $user_problem1, 'updateUserProblem: sucessfully update a field');

	# Update a user problem and return as a merged problem.
	my $updated_problem2 =
		$user_problem_rs->updateUserProblem(info => $problem_info2, params => { seed => 4567 }, merged => 1);
	removeIDs($updated_problem2);
	$problem2->{seed} = 4567;
	$updated_problem2->{status} += 0;

	is($updated_problem2, $problem2,
		'updateUserProblem: sucessfully update a field and return as a merged problem');

	# Update a user problem in the problem_params
	my $updated_problem1a = $user_problem_rs->updateUserProblem(
		info   => $problem_info1,
		params => { problem_params => { library_id => 1234 } }
	);
	removeIDs($updated_problem1a);
	$updated_problem1a->{status} += 0;

	delete $updated_problem1a->{problem_version} unless defined $updated_problem1a->{problem_version};
	$user_problem1->{problem_params}{library_id} = 1234;
	is($updated_problem1a, $user_problem1, 'updateUserProblem: sucessfully update the problem_params');

	# Attempt to update a UserProblem to a non-existent course.
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'course doesn\'t exist',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'updateUserProblem: attempt to update a user problem to a nonexistent course'
	);

	# Attempt to update a UserProblem for a non-existent problem set.
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #999',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'updateUserProblem: attempt to update a user problem for a non-existent problem set'
	);

	# Attempt to add a UserProblem for a non-existent user.
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'non_existent_user',
					set_name       => 'HW #1',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::UserNotFound'),
		'updateUserProblem: attempt to update a user problem for a non-existent user'
	);

	# Attempt to update a UserProblem for a non-existent problem.
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 999
				},
				params => {}
			);
		},
		check_isa('DB::Exception::SetProblemNotFound'),
		'updateUserProblem: attempt to update a user problem for a non-existent problem'
	);

	# Try to update a UserProblem with a bad seed :) .
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { seed => -1234 }
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'updateUserProblem: attempt to update a user problem with a bad seed'
	);

	# Attempt to update a new User Problem with a non existent field
	is(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { non_existent_field => 1 }
			);
		},
		check_isa('DBIx::Class::Exception'),
		'updateUserProblem: attempt to update a user problem with a non existent field'
	);

	# Attempt to update a new User Problem with a non existent field
	like(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { non_existent_field => 1 }
			);
		},
		qr/No such column 'non_existent_field'/,
		'updateUserProblem: attempt to update a user problem with a non existent field'
	);

	# Attempt to update a new User Problem with invalid library id
	like(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { problem_params => { library_id => -1234 } }
			);
		},
		qr/library_id is not valid/,
		'updateUserProblem: attempt to update a user problem with with invalid library id'
	);

	# Attempt to update a new User Problem with a bad problem weight
	like(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { problem_params => { weight => -1 } }
			);
		},
		qr/weight is not valid/,
		'updateUserProblem: attempt to update a user problem with a bad problem weight'
	);

	# Attempt to add a new User Problem with a invalid problem_pool_id
	like(
		dies {
			$user_problem_rs->updateUserProblem(
				info => {
					course_name    => 'Precalculus',
					set_name       => 'HW #4',
					username       => 'ned',
					problem_number => 2
				},
				params => { problem_params => { problem_pool_id => 'fred' } }
			);
		},
		qr/problem_pool_id is not valid/,
		'updateUserProblem: attempt to update a user problem with a bad problem_pool_id'
	);

	# Get an array of user problems for a single user in a course.
	my @user_problems =
		$user_problem_rs->getUserProblemsForUser(info => { course_name => 'Precalculus', username => 'homer' });
	for my $user_problem (@user_problems) {
		removeIDs($user_problem);
		$user_problem->{status} += 0;
	}

	my @course_user_problems_from_json =
		grep { $_->{course_name} eq 'Precalculus' && $_->{username} eq 'homer' } @user_problems_from_json;

	is(
		\@user_problems,
		\@course_user_problems_from_json,
		'getCourseUserProblems: get all user problems for a single user in a course'
	);

	# Delete a User Problem
	my $user_problem_to_delete = $user_problem_rs->deleteUserProblem(info => $problem_info1);
	removeIDs($user_problem_to_delete);
	# the status needs be returned to a numerical value.
	$user_problem_to_delete->{status} += 0;

	delete $user_problem_to_delete->{problem_version}
		unless defined $user_problem_to_delete->{problem_version};

	is($user_problem_to_delete, $user_problem1, 'deleteUserProblem: delete a single user problem');

	# Delete a user problem and return as a merged problem.
	my $user_problem_to_delete2 = $user_problem_rs->deleteUserProblem(info => $problem_info2, merged => 1);
	removeIDs($user_problem_to_delete2);
	# the status needs be returned to a numerical value.
	$user_problem_to_delete2->{status} += 0;

	is($user_problem_to_delete2, $problem2,
		'updateUserProblem: sucessfully update a field and return as a merged problem');

	# Attempt to delete a UserProblem to a non-existent course.
	is(
		dies {
			$user_problem_rs->deleteUserProblem(
				info => {
					course_name    => 'course doesn\'t exist',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::CourseNotFound'),
		'deleteUserProblem: attempt to delete a user problem to a nonexistent course'
	);

	# Attempt to delete a UserProblem for a non-existent problem set.
	is(
		dies {
			$user_problem_rs->deleteUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #999',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'deleteUserProblem: attempt to delete a user problem for a non-existent problem set'
	);

	# Attempt to delete a UserProblem for a non-existent user.
	is(
		dies {
			$user_problem_rs->deleteUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'non_existent_user',
					set_name       => 'HW #1',
					problem_number => 1
				},
				params => {}
			);
		},
		check_isa('DB::Exception::UserNotFound'),
		'deleteUserProblem: attempt to delete a user problem for a non-existent user'
	);

	# Attempt to delete a UserProblem for a non-existent problem.
	is(
		dies {
			$user_problem_rs->deleteUserProblem(
				info => {
					course_name    => 'Precalculus',
					username       => 'homer',
					set_name       => 'HW #1',
					problem_number => 99
				},
				params => {}
			);
		},
		check_isa('DB::Exception::SetProblemNotFound'),
		'deleteUserProblem: attempt to delete a user problem for a non-existent problem'
	);
};

done_testing;

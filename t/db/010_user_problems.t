#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of user problems.
#
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
use Try::Tiny;
use Carp;
use Clone qw/clone/;
use List::MoreUtils qw/firstval/;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs loadSchema/;
use DB::Utils qw/updateAllFields/;

# Set up the database.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);

my $config = LoadFile($config_file);

my $schema =
	DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_problem_rs = $schema->resultset("UserProblem");

# Remove some user problems added via this test.

my @user_problems_to_delete = $user_problem_rs->search(
	{
		'courses.course_name'   => 'Precalculus',
		'problem_sets.set_name' => 'HW #4'
	},
	{
		join => [ { user_sets => { 'problem_sets' => 'courses' } } ]
	}
);

for my $up (@user_problems_to_delete) {
	$up->delete;
}

# Load problems and user problems from the CSV files.
my @user_problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/user_problems.csv");
for my $user_problem (@user_problems_from_csv) {
	$user_problem->{status}              = 1  unless defined($user_problem->{status});
	$user_problem->{user_problem_params} = {} unless defined($user_problem->{user_problem_params});
}

my @problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/problems.csv");
for my $problem (@problems_from_csv) {
	$problem->{status}          = 1 unless defined($problem->{status});
	$problem->{problem_version} = 1 unless defined($problem->{problem_version});
}

my @merged_problems_from_csv = ();
for my $user_problem (@user_problems_from_csv) {
	my $problem = clone firstval {
		$_->{course_name} eq $user_problem->{course_name}
			&& $_->{set_name} eq $user_problem->{set_name}
			&& $_->{problem_number} == $user_problem->{problem_number}
	}
	@problems_from_csv;

	# Override the following fields from user problems.
	for my $key (qw/seed status problem_version username/) {
		$problem->{$key} = $user_problem->{$key} if defined($user_problem->{$key});
	}
	# Override any parameters.
	for my $key (keys %{ $problem->{user_problem_params} }) {
		$problem->{problem_params}->{key} = $problem->{user_problem_params}->{$key}
			if defined $problem->{user_problem_params}->{$key};
	}
	delete $problem->{user_problem_params};

	push(@merged_problems_from_csv, $problem);
}

# Get all user problems.

my @all_user_problems_from_db = $user_problem_rs->getAllUserProblems();
for my $user_problem (@all_user_problems_from_db) {
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
}

is_deeply(\@user_problems_from_csv, \@all_user_problems_from_db,
	"getAllUserProblems: fetch all user problems from the DB.");

# Get merged user problems.

my @merged_problems_from_db = $user_problem_rs->getAllUserProblems(merged => 1);
for my $merged_problem (@merged_problems_from_db) {
	removeIDs($merged_problem);

}

is_deeply(\@merged_problems_from_csv, \@merged_problems_from_db, "getAllUserProblems: fetch all merged problems");

# Get user problems from one course.

my @precalc_user_problems = grep { $_->{course_name} eq "Precalculus" } @user_problems_from_csv;

my @precalc_user_problems_from_db = $user_problem_rs->getUserProblems(info => { course_name => "Precalculus" });
for my $user_problem (@precalc_user_problems_from_db) {
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
}

is_deeply(
	\@precalc_user_problems,
	\@precalc_user_problems_from_db,
	"getUserProblems: get user problems from a single course."
);

# Get merged problems from one course.

my @precalc_merged_problems = grep { $_->{course_name} eq "Precalculus" } @merged_problems_from_csv;

my @precalc_merged_problems_from_db = $user_problem_rs->getUserProblems(
	info   => { course_name => "Precalculus" },
	merged => 1
);
for my $merged_problem (@precalc_merged_problems_from_db) {
	removeIDs($merged_problem);
}

is_deeply(
	\@precalc_merged_problems,
	\@precalc_merged_problems_from_db,
	"getUserProblems: get merged problems from a single course."
);

# Get a single user problem.

my $user_problem = $user_problem_rs->getUserProblem(
	info => {
		course_name    => "Precalculus",
		username       => "homer",
		set_name       => "HW #2",
		problem_number => 3
	}
);
removeIDs($user_problem);
delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};

my $user_problem_from_csv = clone firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{username} eq "homer"
		&& $_->{set_name} eq "HW #2"
		&& $_->{problem_number} == 3
}
@precalc_user_problems;

is_deeply($user_problem_from_csv, $user_problem, "getUserProblem: get a single user problem");

# Get a user problem from a course that doesn't exist.

throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name    => 'course doesn\'t exist',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 1
		}
	);
}
"DB::Exception::CourseNotFound", "getUserProblem: attempt to get a user problem from a nonexistent course";

# Get a user problem from a user that doesn't exist.

throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'non_existent_user',
			set_name       => 'HW #1',
			problem_number => 1
		}
	);
}
"DB::Exception::UserNotFound", "getUserProblem: attempt to get a user problem from a nonexistent user";

# Get a user problem from a set that doesn't exist.

throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #99',
			problem_number => 1
		}
	);
}
"DB::Exception::SetNotInCourse", "getUserProblem: attempt to get a user problem from a nonexistent set";

# Get a user problem from a problem that doesn't exist.

throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 99
		}
	);
}
"DB::Exception::ProblemNotFound", "getUserProblem: attempt to get a user problem from a nonexistent problem";

# Add a UserProblem to the database.

my $problem_info1 = {
	course_name    => "Precalculus",
	set_name       => "HW #4",
	username       => "ned",
	problem_number => 1
};

my $user_problem1 = $user_problem_rs->addUserProblem(
	info   => $problem_info1,
	params => {
		seed => 7329,
		# user_problem_params => {
		# 	# library_id => 34
		# }
	}
);
removeIDs($user_problem1);
$problem_info1->{seed}                = 7329;
$problem_info1->{status}              = 0;
$problem_info1->{user_problem_params} = {};

is_deeply($problem_info1, $user_problem1, "addUserProblem: add a single user problem");

# Add a user problem and get back a merged problem.

my $problem_info2 = {
	course_name    => "Precalculus",
	set_name       => "HW #4",
	username       => "ned",
	problem_number => 2
};

my $user_problem2 = $user_problem_rs->addUserProblem(
	info   => $problem_info2,
	params => {
		seed                => 7329,
		user_problem_params => {
			weight => 2
		}
	},
	merged => 1
);
removeIDs($user_problem2);

my $problem2 = clone firstval {
	$_->{course_name} eq $problem_info2->{course_name}
		&& $_->{set_name} eq $problem_info2->{set_name}
		&& $_->{problem_number} eq $problem_info2->{problem_number}
}
@problems_from_csv;

# Merge the two problems.
for my $key (qw/username seed status problem_version/) {
	$problem2->{$key} = $user_problem2->{$key} if defined $user_problem2->{$key};
}
$problem2->{problem_params}->{weight} = 2;

is_deeply($problem2, $user_problem2, "addUserProblem: add a user problem and return a merged problem");

# Attempt to add a UserProblem to a non-existent course.

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => 'course doesn\'t exist',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::CourseNotFound", "addUserProblem: attempt to add a user problem to a nonexistent course";

# Attempt to add a UserProblem for a non-existent problem set.

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #999',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::SetNotInCourse", "addUserProblem: attempt to add a user problem for a non-existent problem set";

# Attempt to add a UserProblem for a non-existent user.

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'non_existent_user',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::UserNotFound", "addUserProblem: attempt to add a user problem for a non-existent user";

# Attempt to add a UserProblem for a non-existent problem.

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 999
		},
		params => {}
	);
}
"DB::Exception::ProblemNotFound", "addUserProblem: attempt to add a user problem for a non-existent problem";

# Attempt to add a UserProblem that already exists

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::UserProblemExists", "addUserProblem: attempt to add a user problem that already exists";

# Try to add a UserProblem with a bad seed :) .

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			seed => -1234
		}
	);
}
"DB::Exception::InvalidParameter", "addUserProblem: attempt to add a user problem with a bad seed";

# Attempt to add a new User Problem with a non existent field

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			non_existent_field => 1
		}
	);
}
"DBIx::Class::Exception", "addUserProblem: attempt to add a user problem with a non existent field";

# Attempt to add a new User Problem with a non existent field

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			non_existent_field => 1
		}
	);
}
qr/No such column 'non_existent_field'/, "addUserProblem: attempt to add a user problem with a non existent field";

# Attempt to add a new User Problem with invalid library id

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			user_problem_params => {
				library_id => -1234
			}
		}
	);
}
qr/library_id is not valid/, "addUserProblem: attempt to add a user problem with with invalid library id";

# Attempt to add a new User Problem with a bad problem weight

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			user_problem_params => {
				weight => -1
			}
		}
	);
}
qr/weight is not valid/, "addUserProblem: attempt to add a user problem with a bad problem weight";

# Attempt to add a new User Problem with a invalid problem_pool_id

throws_ok {
	$user_problem_rs->addUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 3
		},
		params => {
			user_problem_params => {
				problem_pool_id => 'fred'
			}
		}
	);
}
qr/problem_pool_id is not valid/, "addUserProblem: attempt to add a user problem with a bad problem_pool_id";

# update a user problem and return as a user problem

my $updated_problem1 = $user_problem_rs->updateUserProblem(
	info   => $problem_info1,
	params => {
		seed => 4567
	}
);
removeIDs($updated_problem1);
delete $updated_problem1->{problem_version} unless defined $updated_problem1->{problem_version};
$user_problem1->{seed} = 4567;
is_deeply($user_problem1, $updated_problem1, "updateUserProblem: sucessfully update a field");

# Update a user problem and return as a merged problem.

my $updated_problem2 = $user_problem_rs->updateUserProblem(
	info   => $problem_info2,
	params => {
		seed => 4567
	},
	merged => 1
);
removeIDs($updated_problem2);
use Data::Dumper;
$problem2->{seed} = 4567;

is_deeply($problem2, $updated_problem2, "updateUserProblem: sucessfully update a field and return as a merged problem");

# Update a user problem in the user_problem_params

my $updated_problem1a = $user_problem_rs->updateUserProblem(
	info   => $problem_info1,
	params => {
		user_problem_params => {
			library_id => 1234
		}
	}
);
removeIDs($updated_problem1a);
delete $updated_problem1a->{problem_version} unless defined $updated_problem1a->{problem_version};
$user_problem1->{user_problem_params}->{library_id} = 1234;
is_deeply($user_problem1, $updated_problem1a, "updateUserProblem: sucessfully update the user_problem_params");

# Attempt to update a UserProblem to a non-existent course.

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => 'course doesn\'t exist',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::CourseNotFound", "updateUserProblem: attempt to update a user problem to a nonexistent course";

# Attempt to update a UserProblem for a non-existent problem set.

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #999',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::SetNotInCourse", "updateUserProblem: attempt to update a user problem for a non-existent problem set";

# Attempt to add a UserProblem for a non-existent user.

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'non_existent_user',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::UserNotFound", "updateUserProblem: attempt to update a user problem for a non-existent user";

# Attempt to update a UserProblem for a non-existent problem.

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 999
		},
		params => {}
	);
}
"DB::Exception::ProblemNotFound", "updateUserProblem: attempt to update a user problem for a non-existent problem";

# Try to update a UserProblem with a bad seed :) .

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			seed => -1234
		}
	);
}
"DB::Exception::InvalidParameter", "updateUserProblem: attempt to update a user problem with a bad seed";

# Attempt to update a new User Problem with a non existent field

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			non_existent_field => 1
		}
	);
}
"DBIx::Class::Exception", "updateUserProblem: attempt to update a user problem with a non existent field";

# Attempt to update a new User Problem with a non existent field

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			non_existent_field => 1
		}
	);
}
qr/No such column 'non_existent_field'/,
	"updateUserProblem: attempt to update a user problem with a non existent field";

# Attempt to update a new User Problem with invalid library id

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			user_problem_params => {
				library_id => -1234
			}
		}
	);
}
qr/library_id is not valid/, "updateUserProblem: attempt to update a user problem with with invalid library id";

# Attempt to update a new User Problem with a bad problem weight

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			user_problem_params => {
				weight => -1
			}
		}
	);
}
qr/weight is not valid/, "updateUserProblem: attempt to update a user problem with a bad problem weight";

# Attempt to add a new User Problem with a invalid problem_pool_id

throws_ok {
	$user_problem_rs->updateUserProblem(
		info => {
			course_name    => "Precalculus",
			set_name       => "HW #4",
			username       => "ned",
			problem_number => 2
		},
		params => {
			user_problem_params => {
				problem_pool_id => 'fred'
			}
		}
	);
}
qr/problem_pool_id is not valid/, "updateUserProblem: attempt to update a user problem with a bad problem_pool_id";

# Delete a User Problem

my $user_problem_to_delete = $user_problem_rs->deleteUserProblem(info => $problem_info1);
removeIDs($user_problem_to_delete);
delete $user_problem_to_delete->{problem_version} unless defined $user_problem_to_delete->{problem_version};

is_deeply($user_problem1, $user_problem_to_delete, "deleteUserProblem: delete a single user problem");

# Delete a user problem and return as a merged problem.

my $user_problem_to_delete2 = $user_problem_rs->updateUserProblem(info => $problem_info2, merged => 1);
removeIDs($user_problem_to_delete2);

is_deeply($problem2, $user_problem_to_delete2,
	"updateUserProblem: sucessfully update a field and return as a merged problem");

# Attempt to delete a UserProblem to a non-existent course.

throws_ok {
	$user_problem_rs->deleteUserProblem(
		info => {
			course_name    => 'course doesn\'t exist',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::CourseNotFound", "deleteUserProblem: attempt to delete a user problem to a nonexistent course";

# Attempt to delete a UserProblem for a non-existent problem set.

throws_ok {
	$user_problem_rs->deleteUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #999',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::SetNotInCourse", "deleteUserProblem: attempt to delete a user problem for a non-existent problem set";

# Attempt to add a UserProblem for a non-existent user.

throws_ok {
	$user_problem_rs->deleteUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'non_existent_user',
			set_name       => 'HW #1',
			problem_number => 1
		},
		params => {}
	);
}
"DB::Exception::UserNotFound", "deleteUserProblem: attempt to delete a user problem for a non-existent user";

# Attempt to delete a UserProblem for a non-existent problem.

throws_ok {
	$user_problem_rs->deleteUserProblem(
		info => {
			course_name    => 'Precalculus',
			username       => 'homer',
			set_name       => 'HW #1',
			problem_number => 99
		},
		params => {}
	);
}
"DB::Exception::ProblemNotFound", "deleteUserProblem: attempt to delete a user problem for a non-existent problem";

done_testing;

#!/usr/bin/env perl

# This tests the basic functions related to versioning in user sets.

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Test::More;
use Test::Exception;
use YAML::XS qw/LoadFile/;
use Clone qw/clone/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs/;

# Load the database
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

my $problem_rs      = $schema->resultset('SetProblem');
my $user_problem_rs = $schema->resultset('UserProblem');

# Load problems and user problems from the CSV files.
my @user_problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/user_problems.csv");
for my $user_problem (@user_problems_from_csv) {
	$user_problem->{status}          = 1  unless defined($user_problem->{status});
	$user_problem->{problem_params}  = {} unless defined($user_problem->{problem_params});
	$user_problem->{problem_version} = 1  unless defined($user_problem->{problem_version});
}

my @problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/problems.csv");
for my $problem (@problems_from_csv) {
	$problem->{status}          = 1 unless defined($problem->{status});
	$problem->{problem_version} = 1 unless defined($problem->{problem_version});
}

my @merged_problems_from_csv = ();
for my $user_problem (@user_problems_from_csv) {
	my $problem = clone(
		(
			grep {
				$_->{course_name} eq $user_problem->{course_name}
					&& $_->{set_name} eq $user_problem->{set_name}
					&& $_->{problem_number} == $user_problem->{problem_number}
			} @problems_from_csv
		)[0]
	);

	# Override the following fields from user problems.
	for my $key (qw/seed status problem_version username/) {
		$problem->{$key} = $user_problem->{$key} if defined($user_problem->{$key});
	}
	# Override any parameters from user problems.
	for my $key (keys %{ $user_problem->{problem_params} }) {
		$problem->{problem_params}->{$key} = $user_problem->{problem_params}->{$key}
			if defined $problem->{problem_params}->{$key};
	}
	push(@merged_problems_from_csv, $problem);
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

# Check that it is the same as that from the CSV file

my $user_problem1_from_csv = clone(
	(
		grep {
			$_->{course_name} eq $user_problem_info->{course_name}
				&& $_->{set_name} eq $user_problem_info->{set_name}
				&& $_->{username} eq $user_problem_info->{username}
				&& $_->{problem_number} == $user_problem_info->{problem_number}
		} @user_problems_from_csv
	)[0]
);

# the status needs be returned to a numerical value.
$user_problem1->{status} += 0;

is_deeply($user_problem1_from_csv, $user_problem1, 'getUserProblem: get a single user problem from a course.');

# Make a new user problem that has a problem_version of 2

my $user_problem1_v2_params = clone $user_problem1;
$user_problem1_v2_params->{problem_version} = 2;

my $user_problem1_v2 = $user_problem_rs->addUserProblem(params => { %$user_problem_info, %$user_problem1_v2_params });
removeIDs($user_problem1_v2);

is_deeply($user_problem1_v2_params, $user_problem1_v2, "addUserProblem: add a user problem with version =2 ");

# Make a new user set that has a  set_version of 3

my $user_problem1_v3_params = clone $user_problem1;
$user_problem1_v3_params->{problem_version} = 3;

my $user_problem1_v3 = $user_problem_rs->addUserProblem(params => { %$user_problem_info, %$user_problem1_v3_params });
removeIDs($user_problem1_v3);

is_deeply($user_problem1_v3_params, $user_problem1_v3, "addUserProblem: add a user problem with version =3 ");

my @all_user_problem_versions = $user_problem_rs->getUserProblemVersions(info => $user_problem_info);

for my $user_problem (@all_user_problem_versions) {
	removeIDs($user_problem);
	$user_problem->{status} += 0;
}

is_deeply(
	\@all_user_problem_versions,
	[ $user_problem1, $user_problem1_v2, $user_problem1_v3 ],
	'getUserProblemVersions: get all versions of a user problem'
);

# Clean up the created versioned user problems.
my $user_problem_v2_to_delete = $user_problem_rs->deleteUserProblem(
	info => {
		course_name     => $user_problem1_v2_params->{course_name},
		set_name        => $user_problem1_v2_params->{set_name},
		username        => $user_problem1_v2_params->{username},
		problem_number  => $user_problem1_v2_params->{problem_number},
		problem_version => $user_problem1_v2_params->{problem_version}
	}
);

# Make sure that the user problem successfully was deleted.
throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name     => $user_problem1_v2_params->{course_name},
			set_name        => $user_problem1_v2_params->{set_name},
			username        => $user_problem1_v2_params->{username},
			problem_number  => $user_problem1_v2_params->{problem_number},
			problem_version => $user_problem1_v2_params->{problem_version}
		}
	)
}
'DB::Exception::UserProblemNotFound', 'deleteUserProblem: delete a versioned user problem';

$user_problem_rs->deleteUserProblem(
	info => {
		course_name     => $user_problem1_v3_params->{course_name},
		set_name        => $user_problem1_v3_params->{set_name},
		username        => $user_problem1_v3_params->{username},
		problem_number  => $user_problem1_v3_params->{problem_number},
		problem_version => $user_problem1_v3_params->{problem_version}
	}
);

# Make sure that the user problem successfully was deleted.
throws_ok {
	$user_problem_rs->getUserProblem(
		info => {
			course_name     => $user_problem1_v3_params->{course_name},
			set_name        => $user_problem1_v3_params->{set_name},
			username        => $user_problem1_v3_params->{username},
			problem_number  => $user_problem1_v3_params->{problem_number},
			problem_version => $user_problem1_v3_params->{problem_version}
		}
	)
}
'DB::Exception::UserProblemNotFound', 'deleteUserProblem: delete another versioned user problem';

# Ensure that the user_problems table is restored.
my @all_user_problems_from_db = $user_problem_rs->getAllUserProblems();

for my $user_problem (@all_user_problems_from_db) {
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
}
# For comparision make sure the loaded status are printed to 5 digits.
$_->{status} += 0 for (@all_user_problems_from_db);

is_deeply(\@user_problems_from_csv, \@all_user_problems_from_db, 'check: ensure that user_problems table is restored.');

done_testing;

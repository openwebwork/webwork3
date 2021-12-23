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

# use DB::WithParams;
# use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs loadSchema/;
use DB::Utils qw/updateAllFields/;

# set up the database
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

my $schema =
	DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_problem_rs = $schema->resultset("UserProblem");

# remove some user problems added via this test

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

# load problems and user problems from the CVS files
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

use Data::Dumper;

my @merged_problems_from_csv = ();
for my $user_problem (@user_problems_from_csv) {
	my $problem = clone firstval {
		$_->{course_name} eq $user_problem->{course_name}
			&& $_->{set_name} eq $user_problem->{set_name}
			&& $_->{problem_number} == $user_problem->{problem_number}
	}
	@problems_from_csv;

	# override the following fields from user problems
	for my $key (qw/seed status problem_version username/) {
		$problem->{$key} = $user_problem->{$key} if defined($user_problem->{$key});
	}
	# override any parameters
	for my $key (keys %{ $problem->{user_problem_params} }) {
		$problem->{problem_params}->{key} = $problem->{user_problem_params}->{$key}
			if defined $problem->{user_problem_params}->{$key};
	}
	delete $problem->{user_problem_params};

	push(@merged_problems_from_csv, $problem);
}

# get all user problems

my @all_user_problems_from_db = $user_problem_rs->getAllUserProblems();
for my $user_problem (@all_user_problems_from_db) {
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
}

is_deeply(\@user_problems_from_csv, \@all_user_problems_from_db,
	"getAllUserProblems: fetch all user problems from the DB.");

# get merged user problems

my @merged_problems_from_db = $user_problem_rs->getAllUserProblems(merged => 1);
for my $merged_problem (@merged_problems_from_db) {
	removeIDs($merged_problem);
	# delete $merged_problem->{problem_version} unless defined $merged_problem->{problem_version};
}

is_deeply(\@merged_problems_from_csv, \@merged_problems_from_db, "getAllUserProblems: fetch all merged problems");

# get user problems from one course

my @precalc_user_problems = grep { $_->{course_name} eq "Precalculus" } @user_problems_from_csv;

my @precalc_user_problems_from_db =
	$user_problem_rs->getUserProblems(info => { course_name => "Precalculus" });
for my $user_problem (@precalc_user_problems_from_db) {
	removeIDs($user_problem);
	delete $user_problem->{problem_version} unless defined $user_problem->{problem_version};
}

is_deeply(
	\@precalc_user_problems,
	\@precalc_user_problems_from_db,
	"getUserProblems: get user problems from a single course."
);

# get merged problems from one course

my @precalc_merged_problems = grep { $_->{course_name} eq "Precalculus" } @merged_problems_from_csv;

my @precalc_merged_problems_from_db = $user_problem_rs->getUserProblems(
	info => { course_name => "Precalculus" },
	merged            => 1
);
for my $merged_problem (@precalc_merged_problems_from_db) {
	removeIDs($merged_problem);
}

is_deeply(
	\@precalc_merged_problems,
	\@precalc_merged_problems_from_db,
	"getUserProblems: get merged problems from a single course."
);

# get a single user problem

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

# get a user problem from a course that doesn't exist

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

# get a user problem from a user that doesn't exist

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

# get a user problem from a set that doesn't exist

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

# get a user problem from a problem that doesn't exist

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

# add a user_problem to the database

my $problem_info1 = {
	course_name    => "Precalculus",
	set_name       => "HW #4",
	username       => "ned",
	problem_number => 1
};

my $user_problem1 = $user_problem_rs->addUserProblem(
	info   => $problem_info1,
	user_problem_params => { seed => 7329 }
);
removeIDs($user_problem1);
$problem_info1->{seed}   = 7329;
$problem_info1->{status} = 0;

is_deeply($problem_info1, $user_problem1, "addUserProblem: add a single user problem");

# add a user problem and get back a merged problem

my $problem_info2 = {
	course_name    => "Precalculus",
	set_name       => "HW #4",
	username       => "ned",
	problem_number => 2
};

my $user_problem2 = $user_problem_rs->addUserProblem(
	info   => $problem_info2,
	user_problem_params => { seed => 7329 },
	merged              => 1
);
removeIDs($user_problem2);

my $problem2 = clone firstval {
	$_->{course_name} eq $problem_info2->{course_name}
		&& $_->{set_name} eq $problem_info2->{set_name}
		&& $_->{problem_number} eq $problem_info2->{problem_number}
}
@problems_from_csv;

# merge the two problems;
for my $key (qw/username seed status problem_version/) {
	$problem2->{$key} = $user_problem2->{$key} if defined $user_problem2->{$key};
}
is_deeply($problem2, $user_problem2, "addUserProblem: add a user problem and return a merged problem");

done_testing;

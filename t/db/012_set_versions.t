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
use TestUtils qw/loadCSV removeIDs cleanUndef/;

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

my $problem_set_rs = $schema->resultset('ProblemSet');
my $course_rs      = $schema->resultset('Course');
my $user_rs        = $schema->resultset('User');
my $user_set_rs    = $schema->resultset('UserSet');

# Load HW sets from CSV file
my @hw_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/hw_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}   = 'HW';
	$hw_set->{set_params} = {} unless defined $hw_set->{set_params};

}

my @quizzes = loadCSV(
	"$main::ww3_dir/t/db/sample_data/quizzes.csv",
	{
		boolean_fields           => ['set_visible'],
		param_boolean_fields     => ['timed'],
		param_non_neg_int_fields => ['quiz_duration']
	}
);
for my $quiz (@quizzes) {
	$quiz->{set_type}   = "QUIZ";
	$quiz->{set_params} = {} unless defined($quiz->{set_params});
}

my @review_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/review_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => ['can_retake']
	}
);
for my $set (@review_sets) {
	$set->{set_type}   = 'REVIEW';
	$set->{set_params} = {} unless defined $set->{set_params};

}

my @all_problem_sets = (@hw_sets, @quizzes, @review_sets);

my @all_user_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/user_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);

for my $set (@all_user_sets) {
	$set->{set_version} = 0 unless defined($set->{set_version});
	# find the problem set type
	my $s =
		(grep { $_->{course_name} eq $set->{course_name} && $_->{set_name} eq $set->{set_name} } @all_problem_sets)[0];
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
		$dates->{$d} = $user_set->{set_dates}->{$d};
	}

	# Determine params and dates overrides
	my $params = clone($set->{set_params});
	for my $key (keys %{ $user_set->{set_params} }) {
		$params->{$key} = $user_set->{set_params}->{$key};
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

# Check that it is the same as that from the CSV file

my $user_set1_from_csv = (
	grep {
		$_->{course_name} eq $user_set_info1->{course_name}
			&& $_->{set_name} eq $user_set_info1->{set_name}
			&& $_->{username} eq $user_set_info1->{username}
	} @all_user_sets
)[0];

# Make a new user set that has a  set_version of 1

is_deeply($user_set1_from_csv, $user_set1, 'getUserSet: get a single user set from a course.');

my $user_set1_v1_params = clone $user_set1;
$user_set1_v1_params->{set_version} = 1;

my $user_set1_v1 = $user_set_rs->addUserSet(params => { %$user_set_info1, %$user_set1_v1_params });
removeIDs($user_set1_v1);
cleanUndef($user_set1_v1);

is_deeply($user_set1_v1, $user_set1_v1_params, "addUserSet: add a user set with version =1 ");

# Make a new user set that has a  set_version of 2

my $user_set1_v2_params = clone $user_set1_v1_params;
$user_set1_v2_params->{set_version} = 2;

my $user_set1_v2 = $user_set_rs->addUserSet(params => { %$user_set_info1, %$user_set1_v2_params });
removeIDs($user_set1_v2);
cleanUndef($user_set1_v2);

is_deeply($user_set1_v2, $user_set1_v2_params, "addUserSet: add a user set with  version = 2.");

my @all_user_set_versions = $user_set_rs->getUserSetVersions(info => $user_set_info1);
for my $user_set (@all_user_set_versions) {
	removeIDs($user_set);
	cleanUndef($user_set);
}

is_deeply(
	\@all_user_set_versions,
	[ $user_set1, $user_set1_v1, $user_set1_v2 ],
	'getUserSetVersions: get all versions of a user set.'
);

# Clean up the created versioned user sets.
$user_set_rs->deleteUserSet(
	info => {
		course_name => $user_set1_v1_params->{course_name},
		set_name    => $user_set1_v1_params->{set_name},
		username    => $user_set1_v1_params->{username},
		set_version => $user_set1_v1_params->{set_version}
	}
);

# Make sure that the user set successfully was deleted.
throws_ok {
	$user_set_rs->getUserSet(
		info => {
			course_name => $user_set1_v1_params->{course_name},
			set_name    => $user_set1_v1_params->{set_name},
			username    => $user_set1_v1_params->{username},
			set_version => $user_set1_v1_params->{set_version}
		}
	)
}
'DB::Exception::UserSetNotInCourse', 'deleteUserSet: delete user set with set_version = 1';

$user_set_rs->deleteUserSet(
	info => {
		course_name => $user_set1_v2_params->{course_name},
		set_name    => $user_set1_v2_params->{set_name},
		username    => $user_set1_v2_params->{username},
		set_version => $user_set1_v2_params->{set_version}
	}
);

# Ensure that the user_sets table is restored.
my @all_user_sets_from_db = $user_set_rs->getAllUserSets(merged => 1);

for my $set (@all_user_sets_from_db) {
	removeIDs($set);
	cleanUndef($set);
}

# Sort before comparing.
@merged_user_sets =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @merged_user_sets;
@all_user_sets_from_db =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @all_user_sets_from_db;

is_deeply(\@all_user_sets_from_db, \@merged_user_sets, 'check: Ensure that the user_sets table is restored.');

done_testing;

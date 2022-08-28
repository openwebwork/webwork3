#!/usr/bin/env perl

# This tests the basic database CRUD functions of problem sets of type quiz.

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Test2::V0;
use Clone qw/clone/;

use YAML::XS qw/LoadFile/;
use Mojo::JSON qw/true false/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs cleanUndef/;

# Load the configuration files
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);

my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_set_rs    = $schema->resultset('UserSet');
my $course_rs      = $schema->resultset('Course');
my $course_user_rs = $schema->resultset('CourseUser');
my $problem_set_rs = $schema->resultset('ProblemSet');
my $course         = $course_rs->find({ course_id => 1 });

# Load info from CSV files
my @hw_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/hw_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}   = "HW";
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
for my $set (@quizzes) {
	$set->{set_type}   = "QUIZ";
	$set->{set_params} = {} unless defined $set->{set_params};
}

my @review_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/review_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => ['can_retake']
	}
);

for my $set (@review_sets) {
	$set->{set_type}   = "REVIEW";
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
	$set->{set_params} = {} unless defined $set->{set_params};
	$set->{set_type}   = $s->{set_type};
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
	$user_set->{set_version} = 1                   unless defined($user_set->{set_version});
	$user_set->{set_type}    = $set->{set_type}    unless defined($user_set->{set_type});
	$user_set->{set_visible} = $set->{set_visible} unless defined($user_set->{set_visible});
}

# Get all user sets for a given user in a course.
my @all_user_sets_from_db = $user_set_rs->getAllUserSets();

for my $set (@all_user_sets_from_db) {
	removeIDs($set);
	for my $key (keys %{$set}) {
		delete $set->{$key} unless defined $set->{$key};
	}
}

# sort both arrays
@all_user_sets = sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @all_user_sets;
@all_user_sets_from_db =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @all_user_sets_from_db;

is(\@all_user_sets_from_db, \@all_user_sets, 'getAllUserSets: get all user sets for all courses');

my @merged_sets_from_db = $user_set_rs->getAllUserSets(merged => 1);

for my $merged_set (@merged_sets_from_db) {
	removeIDs($merged_set);
}

# sort both arrays
@merged_sets_from_db =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @merged_sets_from_db;
@merged_user_sets =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @merged_user_sets;

is(\@merged_sets_from_db, \@merged_user_sets, 'getAllUserSets: get all merged sets for all courses');

# Get all user set for a given user in a course.

my @user_sets_for_one_user = grep { $_->{course_name} eq 'Precalculus' && $_->{username} eq 'homer' } @all_user_sets;

my @user_sets_from_db = $user_set_rs->getUserSetsForUser(
	info => {
		course_name => $course->course_name,
		username    => 'homer'
	}
);

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{set_visible} unless defined($user_set->{set_visible});
}

# sort both arrays
@user_sets_from_db      = sort { $a->{set_name} cmp $b->{set_name} } @user_sets_from_db;
@user_sets_for_one_user = sort { $a->{set_name} cmp $b->{set_name} } @user_sets_for_one_user;

is(\@user_sets_from_db, \@user_sets_for_one_user, 'getUserSets: get all user sets for one user');

# Get all merged sets for a given user in a course

my @merged_sets_for_one_user =
	grep { $_->{course_name} eq 'Precalculus' && $_->{username} eq 'homer' } @merged_user_sets;

@merged_sets_from_db = $user_set_rs->getUserSetsForUser(
	info => {
		course_name => $course->course_name,
		username    => 'homer'
	},
	merged => 1
);

for my $merged_set (@merged_sets_from_db) {
	removeIDs($merged_set);
}

is(\@merged_sets_from_db, \@merged_sets_for_one_user, 'getUserSets: get all merged sets for one user');

# get all user sets for a given set in a course

my @user_sets_for_one_set = grep { $_->{course_name} eq 'Precalculus' && $_->{set_name} eq 'HW #1' } @all_user_sets;

@user_sets_from_db = $user_set_rs->getUserSetsForSet(info => { course_name => 'Precalculus', set_name => 'HW #1' });

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{set_visible} unless defined($user_set->{set_visible});
}

is(\@user_sets_from_db, \@user_sets_for_one_set, 'getUserSets: get all user sets for a set in a course');

# get all merged user sets for a given set in a course

my @merged_sets_for_one_set =
	grep { $_->{course_name} eq 'Precalculus' && $_->{set_name} eq 'HW #1' } @merged_user_sets;

@merged_sets_from_db = $user_set_rs->getUserSetsForSet(
	info   => { course_name => 'Precalculus', set_name => 'HW #1' },
	merged => 1
);

for my $user_set (@merged_sets_from_db) {
	removeIDs($user_set);
}

is(\@merged_sets_from_db, \@merged_sets_for_one_set, 'getUserSets: get all merged sets for a set in a course');

# Try to get a user set from a non-existing course.
is(
	dies {
		$user_set_rs->getUserSetsForUser(info => { course_name => 'non_existent_course', username => 'homer' });
	},
	check_isa('DB::Exception::CourseNotFound'),
	'getUserSets: attempt to get user sets from a nonexistent course'
);

# Try to get a user set from a non-existing course.
is(
	dies {
		$user_set_rs->getUserSetsForUser(info => { course_name => 'Precalculus', username => 'non_existent_user' });
	},
	check_isa('DB::Exception::UserNotFound'),
	'getUserSets: attempt to get user sets from a nonexistent user'
);

# Try to get a user set from a user not in the course.
is(
	dies { $user_set_rs->getUserSetsForUser(info => { course_name => 'non_existent_course', username => 'bart' }); }
	,
	check_isa('DB::Exception::CourseNotFound'),
	'getUserSets: attempt to get user sets from user not in the course'
);

# Get a single UserSet
my $info = {
	username    => 'homer',
	course_name => 'Precalculus',
	set_name    => 'HW #1'
};
my $user_set = $user_set_rs->getUserSet(info => $info);

my $user_set_from_csv = clone(
	(
		grep {
			$_->{course_name} eq 'Precalculus'
				&& $_->{username} eq $info->{username}
				&& $_->{set_name} eq $info->{set_name}
		} @all_user_sets
	)[0]
);

removeIDs($user_set);
delete $user_set->{set_visible} unless defined($user_set->{set_visible});

is($user_set, $user_set_from_csv, 'getUserSet: get a user set from a course');

# Get a merged UserSet

my $merged_set_from_csv = clone(
	(
		grep {
			$_->{course_name} eq 'Precalculus'
				&& $_->{username} eq $info->{username}
				&& $_->{set_name} eq $info->{set_name}
		} @merged_user_sets
	)[0]
);

my $merged_set = $user_set_rs->getUserSet(info => $info, merged => 1);
removeIDs($merged_set);

is($merged_set, $merged_set_from_csv, 'getUserSet: get a merged set from a course');

# Try to get a user set from a non-existent course.
is(
	dies {
		$user_set_rs->getUserSet(
			info => { course_name => 'non_existent_course', username => 'homer', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::CourseNotFound'),
	'getUserSet: try to get a user set from a non-existent course'
);

# Try to get a user set from a non-existent user.
is(
	dies {
		$user_set_rs->getUserSet(
			info => { course_name => 'Precalculus', username => 'non_existent_user', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::UserNotFound'),
	'getUserSet: try to get a user set from a non-existent user'
);

# Try to get a user set from a user not in the course.
is(
	dies {
		$user_set_rs->getUserSet(
			info => { course_name => 'Precalculus', username => 'marge', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::UserNotInCourse'),
	'getUserSet: try to get a user set not in the course'
);

# Try to get a user set from a non-existent set.
is(
	dies {
		$user_set_rs->getUserSet(
			info => { course_name => 'Precalculus', username => 'homer', set_name => 'HW #999' });
	},
	check_isa('DB::Exception::SetNotInCourse'),
	'getUserSet: try to get a user set from a non-existent set'
);

# Add a user set
my $new_info = {
	username    => 'otto',
	course_name => 'Precalculus',
	set_name    => 'HW #1'
};

my $new_user_set = $user_set_rs->addUserSet(params => $new_info);
removeIDs($new_user_set);
cleanUndef($new_user_set);

# Set the other default parameters.
$new_info->{set_dates}   = {};
$new_info->{set_params}  = {};
$new_info->{set_version} = 0;
$new_info->{set_type}    = 'HW';

is($new_user_set, $new_info, 'addUserSet: add a new user set');

my $hw_set1 = clone((grep { $_->{course_name} eq 'Precalculus' && $_->{set_name} eq 'HW #1' } @hw_sets)[0]);

$hw_set1->{username} = 'frink';

my $new_merged_set = $user_set_rs->addUserSet(
	params => {
		course_name => 'Precalculus',
		set_name    => 'HW #1',
		username    => 'frink'
	},
	merged => 1
);
removeIDs($new_merged_set);
# add the default value for set_version
$hw_set1->{set_version} = 0;

is($new_merged_set, $hw_set1, 'addUserSet: add a new user set and check that it is merged correctly');

# Add a user set with a empty set of dates.

my $new_user_params2 = {
	username    => 'ralph',
	course_name => 'Arithmetic',
	set_name    => 'HW #3',
	set_dates   => {}
};

my $new_user_set2 = $user_set_rs->addUserSet(params => $new_user_params2);
removeIDs($new_user_set2);
cleanUndef($new_user_set2);

# add some fields to the params that are added when writing to the DB.
$new_user_params2->{set_type}    = 'HW';
$new_user_params2->{set_version} = 0;
$new_user_params2->{set_params}  = {};

is($new_user_set2, $new_user_params2, 'addUserSet: add a new user set with empty dates.');

# Test that adding a field that is not in the database is ignored.
my $user_set_params3 = {
	username    => 'otto',
	course_name => 'Precalculus',
	set_name    => 'HW #3',
	bad_field   => 1,
	set_version => 0,
	set_params  => {},
	set_dates   => {}
};
my $user_set3 = $user_set_rs->addUserSet(params => $user_set_params3);
removeIDs($user_set3);
cleanUndef($user_set3);

# The bad_field isn't returned
delete $user_set_params3->{bad_field};

# and need to explicitly set the type
$user_set_params3->{set_type} = 'HW';

is($user_set3, $user_set_params3, 'addUserSet: add a user set with a bad field');

# Try to add a user set to a course that doesn't exist.
is(
	dies {
		$user_set_rs->addUserSet(
			params => { username => 'otto', course_name => 'non existent course', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::CourseNotFound'),
	'addUserSet: try to add a user set to a non-existent course'
);

# Try to add a user set for a set that does not exist in a course.
is(
	dies {
		$user_set_rs->addUserSet(
			params => { username => 'otto', course_name => 'Precalculus', set_name => 'HW #99' });
	},
	check_isa('DB::Exception::SetNotInCourse'),
	'addUserSet: try to add a user set to a non-existent set'
);

# Try to add a user set for a user that is not in a course.
is(
	dies {
		$user_set_rs->addUserSet(
			params => { username => 'ralph', course_name => 'Abstract Algebra', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::UserNotInCourse'),
	'addUserSet: try to add a user set for a user who is not in the course'
);

# Try to add a user_set that already exists.
is(
	dies {
		$user_set_rs->addUserSet(
			params => { username => 'otto', course_name => 'Precalculus', set_name => 'HW #1' });
	},
	check_isa('DB::Exception::UserSetExists'),
	'addUserSet: try to add a user set that already exists'
);

my $otto_set_info2 = {
	username    => 'otto',
	course_name => 'Precalculus',
	set_name    => 'HW #2',
	set_version => 1
};

# Add a user set with valid params.
my $user_set2 = $user_set_rs->addUserSet(
	params => {
		%$otto_set_info2,
		set_params => {
			description => 'This is the description for HW #2'
		}
	}
);
removeIDs($user_set2);
cleanUndef($user_set2);

my $set_params2 = clone($otto_set_info2);
# set the other default parameters:
$set_params2->{set_dates}   = {};
$set_params2->{set_params}  = { description => 'This is the description for HW #2' };
$set_params2->{set_version} = 1;
$set_params2->{set_type}    = 'HW';

is($user_set2, $set_params2, 'addUserSet: add a new user set with params');

# When adding a user set with a bad field in the params, it is ignored
is(
	dies {
		$user_set_rs->addUserSet(
			params => {
				username    => 'otto',
				course_name => 'Precalculus',
				set_name    => 'HW #4',
				set_version => 1,
				set_params  => { bad_field => 12, hide_hint => false }
			}
		)
	},
	check_isa('DB::Exception::InvalidField'),
	'addUserSet: try to add a new user set with an undefined parameter'
);

# add a user set with a new date

my $set_dates4 = {
	open            => 1,
	reduced_scoring => 800,
	due             => 900,
	answer          => 1000
};

my $otto_set_info4 = {
	username    => 'otto',
	course_name => 'Precalculus',
	set_name    => 'HW #5',
	set_version => 1
};

my $otto_set_info5 = {
	username    => 'otto',
	course_name => 'Precalculus',
	set_name    => 'HW #6',
};

my $otto_set_params4 = { %$otto_set_info4, set_dates => $set_dates4 };

my $user_set4 = $user_set_rs->addUserSet(params => $otto_set_params4);
removeIDs($user_set4);
cleanUndef($user_set4);

my $set_params4 = clone($otto_set_params4);
$set_params4->{set_type}    = 'HW';
$set_params4->{set_params}  = {};
$set_params4->{set_version} = 1;

is($user_set4, $set_params4, 'addUserSet: add a new user set with dates');

# add a user with only override dates set.

my $hw4 = $problem_set_rs->getProblemSet(
	info => {
		course_name => 'Precalculus',
		set_name    => 'HW #4'
	}
);

my $ralph_set_info = {
	username    => 'ralph',
	course_name => 'Precalculus',
	set_name    => 'HW #4',
	set_dates   => {
		open                   => $hw4->{set_dates}->{open} - 100,
		answer                 => $hw4->{set_dates}->{answer} + 100,
		enable_reduced_scoring => false,
	},
	set_params => {
		hide_hint => false
	}
};

my $ralph_user_set = $user_set_rs->addUserSet(params => $ralph_set_info);
removeIDs($ralph_user_set);
cleanUndef($ralph_user_set);

# set some fields that are created from defaults when written to the DB.
$ralph_set_info->{set_type}    = 'HW';
$ralph_set_info->{set_version} = 0;

is($ralph_user_set, $ralph_set_info, 'addUserSet: add a new user with dates (some are missing).');

# Try to add a bad date.
is(
	dies {
		$user_set_rs->addUserSet(
			params => {
				%$otto_set_info5,
				set_dates => { open => 100, due => 9, answer => 1000, enable_reduced_scoring => false }
			}
		);
	},
	check_isa('DB::Exception::ImproperDateOrder'),
	'addUserSet: dates are out of order'
);

is(
	dies {
		$user_set_rs->addUserSet(
			params => { %$otto_set_info5, set_dates => { open => 100, due => 900, answer => 800 } });
	},
	check_isa('DB::Exception::ImproperDateOrder'),
	'addUserSet: dates are out of order'
);
# Add a new user set and test that it is merged correctly.

my $otto_quiz_info = {
	course_name => 'Precalculus',
	set_name    => 'Quiz #1',
	username    => 'otto'
};

# Then add a new user set and test that it is merged correctly.

my $merged_set1 = clone(
	(
		grep {
			$_->{course_name} eq $otto_quiz_info->{course_name}
				&& $_->{set_name} eq $otto_quiz_info->{set_name}
		} @all_problem_sets
	)[0]
);

$merged_set1->{username} = $otto_quiz_info->{username};

my $new_dates = {
	due    => $merged_set->{set_dates}->{answer} + 1000,
	answer => $merged_set->{set_dates}->{answer} + 2000
};

$merged_set1->{set_dates}->{due}    = $new_dates->{due};
$merged_set1->{set_dates}->{answer} = $new_dates->{answer};

my $user_set_to_merge = $user_set_rs->addUserSet(
	params => {
		%$otto_quiz_info, set_dates => $new_dates
	},
	merged => 1
);
removeIDs($user_set_to_merge);
# otto_quiz has set_version 0.  Need to match to compare.
$merged_set1->{set_version} = 0;

is($user_set_to_merge, $merged_set1, 'addUserSet: adding a user set with dates to check merging');

# Check that adding a user set that is out of order with the problem sets throws an error.
# This set has a due date after the answer date.
is(
	dies {
		$user_set_rs->addUserSet(params => { %$otto_set_info5, set_dates => { due => 1609595640 } }, merged => 1);
	},
	check_isa('DB::Exception::ImproperDateOrder'),
	'addUserSet: user set is out of order with respect to problem set'
);

# Check that setting a boolean as 0/1 throws an error
# Currently, this is stripped out if hide_hint is 0.  Do we want to check for this?
is(
	dies {
		$user_set_rs->addUserSet(params => { %$otto_set_info5, set_params => { hide_hint => 1 } }, merged => 1);
	},
	check_isa('DB::Exception::InvalidParameter'),
	'addUserSet: boolean valid should be JSON boolean'
);

# Update User Set

my $otto_quiz = $user_set_rs->getUserSet(info => $otto_quiz_info);
removeIDs($otto_quiz);

# Update the dates
my $updated_dates = {
	due    => $otto_quiz->{set_dates}->{due} + 100,
	answer => $otto_quiz->{set_dates}->{due} + 1000
};

$otto_quiz->{set_dates}->{due}    = $updated_dates->{due};
$otto_quiz->{set_dates}->{answer} = $updated_dates->{answer};

my $updated_user_quiz = $user_set_rs->updateUserSet(info => $otto_quiz_info, params => $otto_quiz);
removeIDs($updated_user_quiz);

is($updated_user_quiz, $otto_quiz, 'updateUserSet: update the dates');

# Update the params
my $updated_user_set2 = $user_set_rs->updateUserSet(
	info   => $otto_quiz_info,
	params => {
		set_params => {
			problem_randorder => true,
		}
	}
);
removeIDs($updated_user_set2);
$otto_quiz->{set_params}->{problem_randorder} = true;
is($updated_user_set2, $otto_quiz, 'updateUserSet: update the params');

# Update a valid field
my $updated_user_set3 = $user_set_rs->updateUserSet(
	info   => $otto_quiz_info,
	params => {
		set_visible => true
	}
);
removeIDs($updated_user_set3);
$otto_quiz->{set_visible} = true;

is($otto_quiz, $updated_user_set3, 'updateUserSet: update the set visibility');

# Try updating an invalid param.
is(
	dies {
		$user_set_rs->updateUserSet(
			info   => $otto_quiz_info,
			params => { set_params => { not_a_valid_param => 'bad' } }
		);
	},
	check_isa('DB::Exception::InvalidField'),
	'updateUserSet: try setting a parameter that does not exist'
);

# Try updating an invalid date.
is(
	dies {
		$user_set_rs->updateUserSet(info => $otto_quiz_info, params => { set_dates => { open => 1, closed => 2 } });
	},
	check_isa('DB::Exception::InvalidField'),
	'updateUserSet: try to update an invalid date field'
);

# Test with out of order dates.
is(
	dies {
		$user_set_rs->updateUserSet(
			info   => $otto_quiz_info,
			params => { set_dates => { open => 100, due => 2, answer => 200 } }
		);
	},
	check_isa('DB::Exception::ImproperDateOrder'),
	'updateUserSet: try to update with out of order dates'
);

# Try to update a user_set that doesn't exist.
is(
	dies {
		$user_set_rs->updateUserSet(info => $otto_set_info5, params => { set_params => { hide_hint => true } });
	},
	check_isa('DB::Exception::UserSetNotInCourse'),
	'updateUserSet: try to update a user set not the in the course'
);

# Try to delete a user_set that doesn't exist.
is(
	dies { $user_set_rs->deleteUserSet(info => $otto_set_info5); },
	check_isa('DB::Exception::UserSetNotInCourse'),
	'deleteUserSet: try to delete a user set not the in the course'
);

# Delete some user sets that were created.

my $deleted_user_set = $user_set_rs->deleteUserSet(
	info => {
		username    => $new_user_set2->{username},
		course_name => $new_user_set2->{course_name},
		set_name    => $new_user_set2->{set_name}
	}
);
removeIDs($deleted_user_set);
cleanUndef($deleted_user_set);
removeIDs($new_user_set2);
cleanUndef($new_user_set2);
is($deleted_user_set, $new_user_set2, "deleteUserSet: successfully delete a user set");

my $deleted_user_set2 = $user_set_rs->deleteUserSet(
	info => {
		username    => $ralph_user_set->{username},
		course_name => $ralph_user_set->{course_name},
		set_name    => $ralph_user_set->{set_name}
	}
);
removeIDs($deleted_user_set2);
cleanUndef($deleted_user_set2);
is($deleted_user_set2, $ralph_user_set, "deleteUserSet: successfully delete another user set");

my $deleted_user_set3 = $user_set_rs->deleteUserSet(info => $otto_quiz_info);
removeIDs($deleted_user_set3);
cleanUndef($deleted_user_set3);
is($deleted_user_set3, $otto_quiz, "deleteUserSet: successfully delete yet another user set");

my $deleted_user_set4 = $user_set_rs->deleteUserSet(info => $new_merged_set);

# remove the rest of the user sets added for user 'otto'

# Test that dates are merged correctly.
# First remove the sets added for user otto.

my @otto_user_sets = $user_set_rs->search(
	{
		'courses.course_name' => 'Precalculus',
		'users.username'      => 'otto',
	},
	{
		join => [ { problem_set => 'courses' }, { course_users => 'users' } ]
	}
);

for my $u (@otto_user_sets) {
	$u->delete;
}

# Check that the user_sets db table is restored.
@all_user_sets_from_db = $user_set_rs->getAllUserSets();

for my $set (@all_user_sets_from_db) {
	removeIDs($set);
	cleanUndef($set);
	for my $key (keys %{$set}) {
		delete $set->{$key} unless defined $set->{$key};
	}
}

# Sort before comparing.
@all_user_sets = sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @all_user_sets;
@all_user_sets_from_db =
	sort { $a->{course_name} cmp $b->{course_name} || $a->{set_name} cmp $b->{set_name} } @all_user_sets_from_db;

is(\@all_user_sets_from_db, \@all_user_sets, 'check: ensure that the user sets are restored.');

done_testing;

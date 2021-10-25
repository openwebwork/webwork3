#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of problem sets of type quiz.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Text::CSV qw/csv/;
use Data::Dumper;
use DateTime::Format::Strptime;

use Test::More;
use Clone qw/clone/;
use Test::Exception;
use List::MoreUtils qw/firstval/;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs loadSchema/;

## get user set info from csv files

## get the database

my $config;
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
if (-e $config_file) {
	$config = LoadFile($config_file);
} else {
	die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?";
}

my $schema =
	DB::Schema->connect($config->{test_database_dsn}, $config->{test_database_user}, $config->{test_database_password});

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_set_rs    = $schema->resultset("UserSet");
my $course_rs      = $schema->resultset("Course");
my $course_user_rs = $schema->resultset("CourseUser");
my $course         = $course_rs->find({ course_id => 1 });

# temporarily delete the added set
my $u                   = $course_user_rs->find({ user_id => 12 });
my $user_sets_to_delete = $user_set_rs->search({ course_user_id => $u->course_user_id });
$user_sets_to_delete->delete_all if $user_sets_to_delete;

# load info from CSV files

my @hw_sets = loadCSV("$main::ww3_dir/t/db/sample_data/hw_sets.csv");
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}    = "HW";
	$hw_set->{set_version} = 1 unless defined($hw_set->{set_version});
	for my $date (keys %{ $hw_set->{dates} }) {
		my $dt = $strp->parse_datetime($hw_set->{dates}->{$date});
		$hw_set->{dates}->{$date} = $dt->epoch;
	}
}
my @all_user_sets = loadCSV("$main::ww3_dir/t/db/sample_data/user_sets.csv");

# merge the sets

for my $user_set (@all_user_sets) {
	my $hw_set = firstval {
		$_->{course_name} eq $user_set->{course_name}
			&& $_->{set_name} eq $user_set->{set_name}
	}
	@hw_sets;

	# determine params and dates overrides
	my $params = clone($hw_set->{params});    # copy the params from the hw_set
	for my $key (keys %{ $user_set->{params} }) {
		$params->{$key} = $user_set->{params}->{$key};
	}
	my $problem_set_dates = clone($hw_set->{dates});
	my @date_fields       = keys %{ $user_set->{dates} };
	my $dates             = (scalar(@date_fields) > 0) ? $user_set->{dates} : $problem_set_dates;

	$user_set->{params}      = {%$params};
	$user_set->{dates}       = {%$dates};
	$user_set->{set_version} = 1 unless defined($user_set->{set_version});
	$user_set->{set_type}    = $hw_set->{set_type};
	$user_set->{set_visible} = $hw_set->{set_visible};
}

## get all user set for a given user in a course

my @user_sets_from_db = $user_set_rs->getUserSetsForUser({
	course_name => $course->course_name,
	username    => "homer"
});

my @user_sets = map {
	{ %{$_} };
} @all_user_sets;    # make a copy of the sets

@user_sets = grep { $_->{course_name} eq $course->course_name && $_->{username} eq "homer" } @user_sets;

for my $user_set (@user_sets) {
	delete $user_set->{course_name};
}

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{type};
}

is_deeply(\@user_sets_from_db, \@user_sets, "getUserSets: get all user sets for a user in a course");

## get all user sets for a given set in a course

@user_sets_from_db = $user_set_rs->getUserSetsForSet({ course_name => "Precalculus", set_name => "HW #1" });

@user_sets = map {
	{ %{$_} };
} @all_user_sets;    # make a copy of the sets
@user_sets = grep { $_->{course_name} eq "Precalculus" && $_->{set_name} eq "HW #1" } @user_sets;

for my $user_set (@user_sets) {
	delete $user_set->{course_name};
}

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{type};
}

is_deeply(\@user_sets_from_db, \@user_sets, "getUserSets: get all user sets for a set in a course");

## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSetsForUser({ course_name => "non_existent_course", username => "homer" });
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from a nonexistent course";

## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSetsForUser({ course_name => "Precalculus", username => "non_existent_user" });
}
"DB::Exception::UserNotInCourse", "getUserSets: attempt to get user sets from a nonexistent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSetsForUser({ course_name => "non_existent_course", username => "bart" });
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from user not in the course";

## get a single UserSet

my $info = {
	username    => "homer",
	course_name => "Precalculus",
	set_name    => "HW #1"
};
my $user_set = $user_set_rs->getUserSet($info);

my @sets = map {
	{ %{$_} };
} @all_user_sets;    # make a copy
my $user_set_from_csv = firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{username} eq $info->{username}
		&& $_->{set_name} eq $info->{set_name}
}
@sets;

removeIDs($user_set);
delete $user_set->{type};
delete $user_set_from_csv->{course_name};

is_deeply($user_set_from_csv, $user_set, "getUserSet: get a user set from a course");

## try to get a user set from a non-existent course

throws_ok {
	$user_set_rs->getUserSet({
		course_name => "non_existent_course",
		username    => "homer",
		set_name    => "HW #1"
	});
}
"DB::Exception::CourseNotFound", "getUserSet: try to get a user set from a non-existent course";

## try to get a user set from a non-existent user

throws_ok {
	$user_set_rs->getUserSet({
		course_name => "Precalculus",
		username    => "non_existent_user",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set from a non-existent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSet({
		course_name => "Precalculus",
		username    => "marge",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set not in the course";

## try to get a user set from a non-existent set

throws_ok {
	$user_set_rs->getUserSet({
		course_name => "Precalculus",
		username    => "homer",
		set_name    => "HW #999"
	});
}
"DB::Exception::SetNotInCourse", "getUserSet: try to get a user set from a non-existent set";

# add a user set

my $new_user_set_info = {
	username    => "otto",
	course_name => "Precalculus",
	set_name    => "HW #1"
};

my $new_user_set = $user_set_rs->addUserSet($new_user_set_info);

my $hw_sets = clone(\@hw_sets);
my $set     = firstval {
	$_->{course_name} eq $new_user_set_info->{course_name}
		&& $_->{set_name} eq $new_user_set_info->{set_name}
}
@$hw_sets;

$set->{username} = $new_user_set_info->{username};
removeIDs($new_user_set);
delete $set->{course_name};
delete $new_user_set->{type};

is_deeply($new_user_set, $set, "addUserSet: add a new user set");

# try to add a user set to a course that doesn't exist

throws_ok {
	$user_set_rs->addUserSet({
		username    => "otto",
		course_name => "non existent course",
		set_name    => "HW #1"
	});
}
"DB::Exception::CourseNotFound", "addUserSet: add a user set to a non-existent course";

# try to add a user set for a set that does not exist in a course

throws_ok {
	$user_set_rs->addUserSet({
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #99"
	});
}
"DB::Exception::SetNotInCourse", "addUserSet: try to add a user set to a non-existent set";

# try to add a user set for a user that is not in a course

throws_ok {
	$user_set_rs->addUserSet({
		username    => "ralph",
		course_name => "Precalculus",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserNotInCourse", "addUserSet: try to add a user set for a user who is not in the course";

# try to add a user set with bad fields

throws_ok {
	$user_set_rs->addUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			bad_field => 1
		}
	);
}
"DBIx::Class::Exception", "addUserSet: try to add a user set with a bad field";

# try to add a user_set that already exists

throws_ok {
	$user_set_rs->addUserSet({
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #1"
	});
}
"DB::Exception::UserSetExists", "addUserSet: try to add a user set that already exists";

## add a user set with valid params

# first delete if it exists.
# my $set2 = $user_set_rs->find({user_id=>12, set_id=>2});
# $set2->delete if defined($set2);

my $user_set2 = $user_set_rs->addUserSet(
	{
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #2"
	},
	{
		params => {
			description => "This is the description for HW #2"
		}
	}
);

$hw_sets = clone(\@hw_sets);
my $set2_from_csv = firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{set_name} eq $user_set2->{set_name}
}
@$hw_sets;

removeIDs($user_set2);
delete $set2_from_csv->{course_name};
delete $user_set2->{type};
$set2_from_csv->{params}   = $user_set2->{params};
$set2_from_csv->{username} = $user_set2->{username};

is_deeply($user_set2, $set2_from_csv, "addUserSet: add a new user set with params");

## try to add a user set with a bad field

throws_ok {
	$user_set_rs->addUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #3"
		},
		{
			params => {
				bad_field => 12
			}
		}
	);
}
"DB::Exception::UndefinedParameter", "addUserSet: try to add a new user set with an undefined parameter";

# delete the user set from from above
my $cu            = $course_user_rs->find({ user_id => 12 }, 1);
my $set_to_delete = $user_set_rs->find({ course_user_id => $cu->course_user_id, set_id => 2 });
$set_to_delete->delete if defined($set_to_delete);

## add a user set with a new date

my $user_set3 = $user_set_rs->addUserSet(
	{
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #2"
	},
	{
		dates => {
			open   => 1,
			due    => 900,
			answer => 1000
		}
	}
);

$hw_sets = clone(\@hw_sets);    # make a copy

my $set3_from_csv = firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{set_name} eq $user_set3->{set_name}
}
@$hw_sets;

removeIDs($user_set3);
delete $set3_from_csv->{course_name};
$set3_from_csv->{dates}    = $user_set3->{dates};
$set3_from_csv->{username} = $user_set3->{username};

is_deeply($user_set3, $set3_from_csv, "addUserSet: add a new user set with dates");

## try to add a bad date

throws_ok {
	$user_set_rs->addUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #3"
		},
		{
			dates => {
				open   => 100,
				due    => 9,
				answer => 1000
			}
		}
	);
}
"DB::Exception::ImproperDateOrder", "addUserSet: dates are out of order";

throws_ok {
	$user_set_rs->addUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #3"
		},
		{
			dates => {
				open   => 100,
				due    => 900,
				answer => 800
			}
		}
	);
}
"DB::Exception::ImproperDateOrder", "addUserSet: dates are out of order";

## Update User Set

# update the dates

my $updated_dates = {
	open   => 1,
	due    => 10,
	answer => 20
};

$set3_from_csv->{dates} = $updated_dates;

my $updated_user_set = $user_set_rs->updateUserSet(
	{
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #2"
	},
	{ dates => $updated_dates }
);

removeIDs($updated_user_set);

is_deeply($updated_user_set, $set3_from_csv, "updateUserSet: update the dates");

# update the params

my $updated_user_set2 = $user_set_rs->updateUserSet(
	{
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #2"
	},
	{
		params => {
			hide_hint => 1,
		}
	}
);

removeIDs($updated_user_set2);

$set3_from_csv->{params}->{hide_hint} = 1;

is_deeply($updated_user_set2, $set3_from_csv, "updateUserSet: update the params");

# try updating an invalid field

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			set_version => 2
		}
	);
}
"DB::Exception::InvalidParameter", "updateUserSet: try setting a parameter that is not allowed to be updated";

# try updating an invalid field

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			params => {
				not_a_valid_param => "bad"
			}
		}
	);
}
"DB::Exception::UndefinedParameter", "updateUserSet: try setting a parameter that is not allowed to be updated";

# try updating an invalid date

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			dates => { open => 1, closed => 2 }
		}
	);
}
"DB::Exception::InvalidDateField", "updateUserSet: try to update an invalid date field";

# missing required dates

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			dates => { open => 1, due => 2 }
		}
	);
}
"DB::Exception::RequiredDateFields", "updateUserSet: try to update with missing required dates";

# out of order dates

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #2"
		},
		{
			dates => { open => 100, due => 2, answer => 200 }
		}
	);
}
"DB::Exception::ImproperDateOrder", "updateUserSet: try to update with out of order dates";

# update a user_set that doesn't exist;

throws_ok {
	$user_set_rs->updateUserSet(
		{
			username    => "otto",
			course_name => "Precalculus",
			set_name    => "HW #3"
		},
		{
			params => {
				hide_hint => 1
			}
		}
	);
}
"DB::Exception::UserSetNotInCourse", "updateUserSet: try to update a user set not the in the course";

# delete a user set

my $deleted_user_set = $user_set_rs->deleteUserSet({
	username    => "otto",
	course_name => "Precalculus",
	set_name    => "HW #2"
});

removeIDs($deleted_user_set);

is_deeply($deleted_user_set, $set3_from_csv, "deleteUserSet: successfully delete a user set");

# delete a user_set that doesn't exist;

throws_ok {
	$user_set_rs->deleteUserSet({
		username    => "otto",
		course_name => "Precalculus",
		set_name    => "HW #3"
	});
}
"DB::Exception::UserSetNotInCourse", "deleteUserSet: try to delete a user set not the in the course";

done_testing;

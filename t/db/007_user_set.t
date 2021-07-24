#
# This tests the basic database CRUD functions of problem sets of type quiz.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path( dirname(__FILE__) );
	$main::lib_dir  = dirname( dirname($main::test_dir) ) . '/lib';
}

use lib "$main::lib_dir";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;
use List::MoreUtils qw/firstval/;
use Try::Tiny;

use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;

## get user set info from csv files

## get the database

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my $user_set_rs = $schema->resultset("UserSet");
my $course_rs   = $schema->resultset("Course");
my $course      = $course_rs->find( { course_id => 1 } );

# my @results = $user_set_rs->search({set_id => 3}, {prefetch => ["course_users"]});

# dd map { {$_->get_inflated_columns, $_->course_users->get_inflated_columns}; } @results;

# die;

# load info from CSV files

my @hw_sets = loadCSV("$main::test_dir/sample_data/hw_sets.csv");
for my $hw_set (@hw_sets) {
	$hw_set->{set_type} = "HW";
}
my @all_user_sets = loadCSV("$main::test_dir/sample_data/user_sets.csv");

# merge the sets

for my $user_set (@all_user_sets) {
	my $hw_set = firstval {
		$_->{course_name} eq $user_set->{course_name}
			&& $_->{set_name} eq $user_set->{set_name}
	}
	@hw_sets;

	# determine params and dates overrides
	my $params = { %{ $hw_set->{params} } };    # copy the params from the hw_set
	for my $key ( keys %{ $user_set->{params} } ) {
		$params->{$key} = $user_set->{params}->{$key};
	}
	my $dates = { %{ $hw_set->{dates} } };
	for my $key ( keys %{ $user_set->{dates} } ) {
		$dates->{$key} = $user_set->{dates}->{$key};
	}
	$user_set->{params}      = {%$params};
	$user_set->{dates}       = {%$dates};
	$user_set->{set_version} = 1 unless defined( $user_set->{set_version} );
	$user_set->{set_type}    = $hw_set->{set_type};
}

## get all user set for a given user in a course

my @user_sets_from_db = $user_set_rs->getUserSets( { course_name => "Precalculus", login => "homer" } );

my @user_sets = grep { $_->{course_name} eq "Precalculus" && $_->{login} eq "homer" } @all_user_sets;

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{type};
}

is_deeply( \@user_sets_from_db, \@user_sets, "getUserSets: get all user sets for a user in a course" );

## get all user sets for a given set in a course

@user_sets_from_db = $user_set_rs->getUserSets( { course_name => "Precalculus", set_name => "HW #1" } );

@user_sets = grep { $_->{course_name} eq "Precalculus" && $_->{set_name} eq "HW #1" } @all_user_sets;

for my $user_set (@user_sets_from_db) {
	removeIDs($user_set);
	delete $user_set->{type};
}

is_deeply( \@user_sets_from_db, \@user_sets, "getUserSets: get all user sets for a set in a course" );

## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSets( { course_name => "non_existent_course", login => "homer" } );
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from a nonexistent course";

## try to get a user set from a non-existing course

throws_ok {
	$user_set_rs->getUserSets( { course_name => "Precalculus", login => "non_existent_user" } );
}
"DB::Exception::UserNotInCourse", "getUserSets: attempt to get user sets from a nonexistent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSets( { course_name => "non_existent_course", login => "bart" } );
}
"DB::Exception::CourseNotFound", "getUserSets: attempt to get user sets from user not in the course";

## get a single UserSet

my $info = {
	login       => "homer",
	course_name => "Precalculus",
	set_name    => "HW #1"
};
my $user_set = $user_set_rs->getUserSet($info);

my $user_set_from_csv = firstval {
	$_->{course_name} eq "Precalculus"
		&& $_->{login} eq $info->{login}
		&& $_->{set_name} eq $info->{set_name}
}
@all_user_sets;

removeIDs($user_set);
delete $user_set->{type};
delete $user_set_from_csv->{course_name};

is_deeply( $user_set_from_csv, $user_set, "getUserSet: get a user set from a course" );

## try to get a user set from a non-existent course

throws_ok {
	$user_set_rs->getUserSet(
		{   course_name => "non_existent_course",
			login       => "homer",
			set_name    => "HW #1"
		}
	);
}
"DB::Exception::CourseNotFound", "getUserSet: try to get a user set from a non-existent course";

## try to get a user set from a non-existent user

throws_ok {
	$user_set_rs->getUserSet(
		{   course_name => "Precalculus",
			login       => "non_existent_user",
			set_name    => "HW #1"
		}
	);
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set from a non-existent user";

## try to get a user set from a user not in the course

throws_ok {
	$user_set_rs->getUserSet(
		{   course_name => "Precalculus",
			login       => "marge",
			set_name    => "HW #1"
		}
	);
}
"DB::Exception::UserNotInCourse", "getUserSet: try to get a user set not in the course";

## try to get a user set from a non-existent set

throws_ok {
	$user_set_rs->getUserSet(
		{   course_name => "Precalculus",
			login       => "homer",
			set_name    => "HW #999"
		}
	);
}
"DB::Exception::SetNotInCourse", "getUserSet: try to get a user set from a non-existent set";

my $updated_params = { dates => { open => 10, reduced_scoring => 30 } };

my $updated_set = $user_set_rs->updateUserSet( $info, $updated_params );

done_testing;

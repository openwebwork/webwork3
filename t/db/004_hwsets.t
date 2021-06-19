#
# This tests the basic database CRUD functions of problem sets.
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
use List::MoreUtils qw(uniq);
use Test::More;
use Test::Exception;
use Try::Tiny;

use Array::Utils qw/array_minus intersect/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs filterBySetType/;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my @hw_dates  = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES;
my @hw_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS;

my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs      = $schema->resultset("Course");
my $user_rs        = $schema->resultset("User");

# load HW sets from CSV file
my @hw_sets = loadCSV("$main::test_dir/sample_data/hw_sets.csv");
for my $set (@hw_sets) {
	$set->{type}        = 1;
	$set->{set_type}    = "HW";
	$set->{set_version} = 1 unless defined( $set->{set_version} );
}
my @quizzes = loadCSV("$main::test_dir/sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{type}        = 2;
	$quiz->{set_type}    = "QUIZ";
	$quiz->{set_version} = 1 unless defined( $quiz->{set_version} );
}
my @review_sets = loadCSV("$main::test_dir/sample_data/review_sets.csv");
for my $set (@review_sets) {
	$set->{type}        = 4;
	$set->{set_type}    = "REVIEW";
	$set->{set_version} = 1 unless defined( $set->{set_version} );
}
my @all_problem_sets = ( @hw_sets, @quizzes, @review_sets );

## Test getting all problem sets

my @problem_sets_from_db = $problem_set_rs->getAllProblemSets;

## remove the id tags:
for my $set (@problem_sets_from_db) {
	removeIDs($set);
	delete $set->{course_params};
	delete $set->{course_dates};
}

is_deeply( \@all_problem_sets, \@problem_sets_from_db, "getProblemSets: get all sets" );

## test for all sets in one course

# filter the precalculus sets:
my @precalc_sets = filterBySetType( \@all_problem_sets, undef, "Precalculus" );

## make a clone of the sets:
@precalc_sets = map {
	{%$_};
} @precalc_sets;

for my $set (@precalc_sets) {
	delete $set->{course_name};
}
@precalc_sets = sort { $a->{set_name} cmp $b->{set_name} } @precalc_sets;

my @precalc_sets_from_db = $problem_set_rs->getProblemSets( { course_name => "Precalculus" } );

# remove id tags:
for my $set (@precalc_sets_from_db) {
	removeIDs($set);
}

is_deeply( \@precalc_sets, \@precalc_sets_from_db, "getProblemSets: get sets for one course" );

## test all HW sets in one course

my @precalc_hw = filterBySetType( \@all_problem_sets, "HW", "Precalculus" );
@precalc_hw = map {
	{%$_};
} @precalc_hw;    # make a clone

for my $set (@precalc_hw) {
	delete $set->{course_name};
}
@precalc_hw = sort { $a->{set_name} cmp $b->{set_name} } @precalc_hw;
my @precalc_hw_from_db = $problem_set_rs->getHWSets( { course_name => "Precalculus" } );

# remove id tags:
for my $set (@precalc_hw_from_db) {
	removeIDs($set);
}

is_deeply( \@precalc_hw, \@precalc_hw_from_db, "getHWSets: get all homework for one course" );

## get one Problem set

my $set_one     = $precalc_hw[0];
my $set_from_db = $problem_set_rs->getProblemSet( { course_name => "Precalculus", set_name => $set_one->{set_name} } );
removeIDs($set_from_db);
is_deeply( $set_one, $set_from_db, "getProblemSet: get one homework" );

## get a problem set that doesn't exist.

throws_ok {
	$problem_set_rs->getProblemSet( { course_name => "Precalculus", set_name => "nonexistent_set" } );
}
"DB::Exception::SetNotInCourse", "getProblemSet: non-existent set name";

throws_ok {
	$problem_set_rs->getProblemSet( { course_name => "Precalculus", set_id => 99999 } );
}
"DB::Exception::SetNotInCourse", "getProblemSet: non-existent set_id";

## add a new problem set

my $new_set_params = {
	set_name => "HW #9",
	dates    => { open => 100, reduced_scoring => 120, due => 140, answer => 200 },
	set_type => "HW"
};

my $new_set    = $problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set_params );
my $new_set_id = $new_set->{set_id};
removeIDs($new_set);
delete $new_set->{type};

is_deeply( $new_set_params, $new_set, "addProblemSet: add one homework" );

## try to add a homework without set_name

my $new_set2 = {
	name     => "HW #11",
	dates    => { open => 100, due => 140, answer => 200 },
	set_type => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set2 );
}
"DB::Exception::ParametersNeeded", "addProblemSet: set_name not passed in.";

## try to add a homework with bad date fields

my $new_set3 = {
	set_name => "HW #11",
	dates    => { open_set => 100, due => 140, answer => 200 },
	set_type => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set3 );
}
"DB::Exception::InvalidDateField", "addProblemSet: invalid date field passed in.";

## try to add a homework set without all required date fields

my $new_set4 = {
	set_name => "HW #11",
	dates    => { open => 100, due => 140 },
	set_type => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set4 );
}
"DB::Exception::RequiredDateFields", "addProblemSet: missing required date fields";

## try to add a homework set without all required date fields

my $new_set5 = {
	set_name => "HW #11",
	dates    => { open => 100, due => 140, answer => "1234s" },
	set_type => "HW"
};
throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set5 );
}
"DB::Exception::InvalidDateFormat", "addProblemSet: adding a non-numeric date";

## try to add a homework set without invalid date order

my $new_set6 = {
	set_name => "HW #11",
	dates    => { open => 100, due => 140, answer => 10 },
	set_type => "HW",
	params   => {}
};
throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set6 );
}
"DB::Exception::ImproperDateOrder", "addProblemSet: adding an illegal date order.";

## check for undefined parameter fields

my $new_set7 = {
	set_name => "HW #11",
	dates    => { open => 100, due => 140, answer => 200 },
	set_type => "HW",
	params   => { has_reduced_scoring => 0, not_a_valid_field => 5 }
};

throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set7 );
}
"DB::Exception::UndefinedParameter", "addProblemSet: adding an undefined parameter field";

## check for invalid parameter fields

my $new_set8 = {
	set_name => "HW #11",
	dates    => { open => 100, due => 140, answer => 200 },
	set_type => "HW",
	params   => { has_reduced_scoring => 0, hide_hints => "yes" }
};
throws_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set8 );
}
"DB::Exception::InvalidParameter", "addProblemSet: adding an non-valid parameter";

## update a set

$new_set_params->{set_name}    = "HW #8";
$new_set_params->{params}      = { has_reduced_scoring => 1 };
$new_set_params->{type}        = 1;
$new_set_params->{set_version} = 1;

my $updated_set = $problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
	{ set_name => $new_set_params->{set_name}, params => { has_reduced_scoring => 1 } } );
removeIDs($updated_set);

is_deeply( $new_set_params, $updated_set, "updateSet: change the set parameters" );

## try to update a set with an illegal field

throws_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id }, { bad_field => 0 } );
}
"DBIx::Class::Exception", "updateProblemSet: use a non-existing field";

## try to update a set with an illegal date field

throws_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
		{ dates => { bad_date => 99 } } );
}
"DB::Exception::InvalidDateField", "updateSet: invalid date field passed in.";

## try to update a set with an dates in a bad order

throws_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
		{ dates => { open => 999, answer => 100 } } );
}
"DB::Exception::ImproperDateOrder", "updateSet: adding an illegal date order.";

## delete a set

my $deleted_set = $problem_set_rs->deleteProblemSet( { course_name => "Precalculus", set_name => "HW #8" } );
removeIDs($deleted_set);

is_deeply( $new_set_params, $deleted_set, "deleteProblemSet: delete a set" );

done_testing;

1;

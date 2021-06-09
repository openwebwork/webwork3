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
	$set->{type} = 1;
}
my @quizzes = loadCSV("$main::test_dir/sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{type} = 2;
}
my @review_sets = loadCSV("$main::test_dir/sample_data/review_sets.csv");
for my $set (@review_sets) {
	$set->{type} = 4;
}
my @all_problem_sets = ( @hw_sets, @quizzes, @review_sets );

## Test getting all problem sets

my @problem_sets_from_db = $problem_set_rs->getAllProblemSets;

## remove the id tags:
for my $set (@problem_sets_from_db) {
	removeIDs($set);
}

is_deeply( \@all_problem_sets, \@problem_sets_from_db, "getProblemSets: get all sets" );

## test for all sets in one course

# filter the precalculus sets:
my @precalc_sets = filterBySetType( \@all_problem_sets, undef, "Precalculus" );

## make a clone of the sets: 
@precalc_sets = map { {%$_}; } @precalc_sets; 

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
@precalc_hw = map { {%$_}; } @precalc_hw ; # make a clone

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

dies_ok {
	$problem_set_rs->getProblemSet( { course_name => "Precalculus", set_name => "nonexistent_set" } );
}
"getProblemSet: non-existent set name";
dies_ok {
	$problem_set_rs->getProblemSet( { course_name => "Precalculus", set_id => 99999 } );
}
"getProblemSet: non-existent set_id";

## add a new problem set

my $new_set_params = {
	set_name => "HW #9",
	dates    => { open => 100, reduced_scoring => 120, due => 140, answer => 200 },
	set_type => "HW"
};

my $new_set    = $problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set_params );
my $new_set_id = $new_set->{set_id};
removeIDs($new_set);

is_deeply( $new_set_params, $new_set, "addProblemSet: add one homework" );

## try to add a homework set with bad date fields

my $new_set2 = {
	name     => "HW #11",
	dates    => { open_set => 100, due => 140, answer => 200 },
	set_type => "HW"
};

dies_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set2 );
}
"addProblemSet: illegal date field";

## try to add a homework set without all required date fields

my $new_set3 = {
	name     => "HW #11",
	dates    => { open => 100, due => 140 },
	set_type => "HW"
};

dies_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set3 );
}
"addProblemSet: not all required date fields";

## try to add a homework set without all required date fields

my $new_set4 = {
	name     => "HW #11",
	dates    => { open => 100, due => 140, answer => "1234s" },
	set_type => "HW"
};
dies_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set4 );
}
"addProblemSet: adding a non-numeric date";

## try to add a homework set without invalid param fields

my $new_set5 = {
	name     => "HW #11",
	dates    => { open => 100, due => 140, answer => 200 },
	set_type => "HW",
	params   => { has_reduced_scoring => 0, not_a_valid_field => 5 }
};
dies_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set5 );
}
"addProblemSet: adding an non-valid parameter";

## validate the parameters

my $new_set6 = {
	name     => "HW #11",
	dates    => { open => 100, due => 140, answer => 200 },
	set_type => "HW",
	params   => { visible => 0, hide_hints => "no" }
};
dies_ok {
	$problem_set_rs->addProblemSet( { course_name => "Precalculus" }, $new_set6 );
}
"addProblemSet: adding an non-valid parameter";

## update a set

$new_set_params->{set_name} = "HW #8";
$new_set_params->{params}   = { has_reduced_scoring => 1 };
$new_set_params->{type}     = 1;

my $updated_set = $problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
	{ set_name => $new_set_params->{set_name}, params => { has_reduced_scoring => 1 } } );
removeIDs($updated_set);

is_deeply( $new_set_params, $updated_set, "updateSet: change the set parameters" );

## try to update a set with an illegal field

dies_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id }, { bad_field => 0 } );
}
"updateProblemSet: use a non-existing field";

## try to update a set with an illegal date field

dies_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
		{ dates => { open => "abc" } } );
}
"updateSet: illegal date set";

## try to update a set with an dates in a bad order

dies_ok {
	$problem_set_rs->updateProblemSet( { course_name => "Precalculus", set_id => $new_set_id },
		{ dates => { open => 999, answer => 100 } } );
}
"updateSet: dates in bad order";

## delete a set

my $deleted_set = $problem_set_rs->deleteProblemSet( { course_name => "Precalculus", set_name => "HW #8" } );
removeIDs($deleted_set);

is_deeply( $new_set_params, $deleted_set, "deleteProblemSet: delete a set" );

done_testing;

1;

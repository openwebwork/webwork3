#
# This tests the basic database CRUD functions of problems.
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

# use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use Test::More;
use Test::Exception;
use Try::Tiny;
use Carp;

use Array::Utils qw/array_minus intersect/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

# $schema->storage->debug(1);  # print out the SQL commands.

my $problem_rs = $schema->resultset("Problem");

# load all problems from the CVS files
my @problems_from_csv = loadCSV("$main::test_dir/sample_data/problems.csv");
for my $problem (@problems_from_csv) {
	$problem->{problem_version} = 1 unless defined( $problem->{problem_version} );
}

# filter out precalc problems
my @precalc_problems = grep { $_->{course_name} eq "Precalculus" } @problems_from_csv;

# filter out "HW #1"
my @precalc_problems1 = grep { $_->{set_name} eq "HW #1" } @precalc_problems;

my @all_problems = map {
	{%$_};
} @problems_from_csv;    # clone of all problems

for my $problem (@all_problems) {
	delete $problem->{course_name};
	delete $problem->{set_name};
}

my @problems_from_db = $problem_rs->getGlobalProblems;
for my $problem (@problems_from_db) {
	removeIDs($problem);
}

is_deeply( \@all_problems, \@problems_from_db, "getGlobalProblems: get all problems" );

## get all problems from one course

my @precalc_problems_from_db = $problem_rs->getProblems( { course_name => "Precalculus" } );
for my $problem (@precalc_problems_from_db) {
	removeIDs($problem);
	$problem->{course_name} = "Precalculus";
	delete $problem->{dates};
}

is_deeply( \@precalc_problems, \@precalc_problems_from_db, "getProblems: get all problems from one course" );

## get all problems in one course from one set.

my @set_problems1 = $problem_rs->getSetProblems( { course_name => "Precalculus", set_name => "HW #1" } );

for my $problem (@set_problems1) {
	removeIDs($problem);
	$problem->{set_name}    = "HW #1";
	$problem->{course_name} = "Precalculus";
}
is_deeply( \@precalc_problems1, \@set_problems1, "getSetProblems: get all problems from one set" );

## try to get problems from a non-existing course

throws_ok {
	$problem_rs->getSetProblems( { course_name => "non_existing_course", set_name => "HW #1" } );
}
"DB::Exception::CourseNotFound", "getSetProblem: get problems from non-existing course";

## try to get problems from a non-existing set

throws_ok {
	$problem_rs->getSetProblems( { course_name => "Precalculus", set_name => "HW #999" } );
}
"DB::Exception::SetNotInCourse", "getSetProblems: get problems from non-existing set";

## get a single problem from a course:

my $set_problem = $problem_rs->getSetProblem(
	{   course_name    => $problems_from_csv[0]->{course_name},
		set_name       => $problems_from_csv[0]->{set_name},
		problem_number => $problems_from_csv[0]->{problem_number}
	}
);
removeIDs($set_problem);

my $expected_problem = { %{ $problems_from_csv[0] } };    # copy the first problem
delete $expected_problem->{set_name};
delete $expected_problem->{course_name};

is_deeply( $expected_problem, $set_problem, "getSetProblem: get a single problem from a set in a given course" );

## add a problem to an existing set

my $new_problem = {
	problem_number => 4,
	params         => {
		library_id => 13245,
		weight     => 1
	}
};

my $prob1 = $problem_rs->addSetProblem(
	{
		course_name => "Precalculus",
		set_name => "HW #1"
	},
	$new_problem
);
removeIDs($prob1);
is_deeply( $new_problem, $prob1, "addProblem: add a valid problem to a set" );

## delete a problem from a set

my $deleted_problem = $problem_rs->deleteSetProblem(
	{   course_name    => "Precalculus",
		set_name       => "HW #1",
		problem_number => 4,
	}
);
removeIDs($deleted_problem);
$new_problem->{problem_version} = 1 unless defined( $new_problem->{problem_version} );

is_deeply( $new_problem, $deleted_problem, "deleteSetProblem: delete one problem in an existing set." );

done_testing;

1;

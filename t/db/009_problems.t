#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of problems.
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
use YAML::XS qw/LoadFile/;

use Array::Utils qw/array_minus intersect/;

use DB::WithParams;
use DB::WithDates;
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

my $problem_rs     = $schema->resultset("Problem");
my $problem_set_rs = $schema->resultset("ProblemSet");

# load all problems from the CVS files
my @problems_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/problems.csv");
for my $problem (@problems_from_csv) {
	$problem->{problem_version} = 1 unless defined($problem->{problem_version});
}

use Data::Dumper;

# filter out precalc problems
my @precalc_problems = grep { $_->{course_name} eq "Precalculus" } @problems_from_csv;

# filter out "HW #1"
my @precalc_problems1 = grep { $_->{set_name} eq "HW #1" } @precalc_problems;

for my $problem (@problems_from_csv) {
	$problem->{problem_version} = 1 unless defined($problem->{problem_version});
	delete $problem->{course_name};
}

my @all_problems = map { clone($_) } @problems_from_csv;

my @problems_from_db = $problem_rs->getGlobalProblems;
for my $problem (@problems_from_db) {
	removeIDs($problem);
}

is_deeply(\@all_problems, \@problems_from_db, "getGlobalProblems: get all problems");

## get all problems from one course

my @precalc_problems_from_db = $problem_rs->getProblems(info => { course_name => "Precalculus" });
for my $problem (@precalc_problems_from_db) {
	removeIDs($problem);
}

for my $problem (@precalc_problems) {
	delete $problem->{set_name};
}

is_deeply(\@precalc_problems, \@precalc_problems_from_db, "getProblems: get all problems from one course");

## get all problems in one course from one set.

my @set_problems1 = $problem_rs->getSetProblems(info => { course_name => "Precalculus", set_name => "HW #1" });

for my $problem (@set_problems1) {
	removeIDs($problem);
}

is_deeply(\@precalc_problems1, \@set_problems1, "getSetProblems: get all problems from one set");

## try to get problems from a non-existing course

throws_ok {
	$problem_rs->getSetProblems(info => { course_name => "non_existing_course", set_name => "HW #1" });
}
"DB::Exception::CourseNotFound", "getSetProblem: get problems from non-existing course";

## try to get problems from a non-existing set

throws_ok {
	$problem_rs->getSetProblems(info => { course_name => "Precalculus", set_name => "HW #999" });
}
"DB::Exception::SetNotInCourse", "getSetProblems: get problems from non-existing set";

## get a single problem from a course:

my $set_problem = $problem_rs->getSetProblem(info => {
	course_name    => "Precalculus",
	set_name       => "HW #1",
	problem_number => $problems_from_csv[0]->{problem_number}
});
removeIDs($set_problem);

my $expected_problem = { %{ $problems_from_csv[0] } };    # copy the first problem
delete $expected_problem->{set_name};
delete $expected_problem->{course_name};

is_deeply($expected_problem, $set_problem, "getSetProblem: get a single problem from a set in a given course");

## add a problem to an existing set

my $new_problem = {
	problem_number => 4,
	problem_params => {
		library_id => 13245,
		weight     => 1
	}
};

my $prob1 = $problem_rs->addSetProblem(
	info => {
		course_name => "Precalculus",
		set_name    => "HW #1"
	},
	params => $new_problem
);
my $prob_id = $prob1->{problem_id};
removeIDs($prob1);

is_deeply($new_problem, $prob1, "addProblem: add a valid problem to a set");

## update a problem

my $updated_params = {
	problem_number => 99,
	problem_params => {
		weight => 2
	}
};

my $all_params      = updateAllFields($new_problem, $updated_params);
my $updated_problem = $problem_rs->updateSetProblem(
	info => {
		course_name => "Precalculus",
		set_name    => "HW #1",
		problem_id  => $prob_id
	},
	params => $updated_params
);
removeIDs($updated_problem);

$all_params->{problem_version} = 1 unless defined $all_params->{problem_version};

is_deeply($all_params, $updated_problem, "updateProblem: update a problem");

## delete a problem from a set

my $deleted_problem = $problem_rs->deleteSetProblem(info => {
	course_name    => "Precalculus",
	set_name       => "HW #1",
	problem_number => 99,
});
removeIDs($deleted_problem);
$new_problem->{problem_version} = 1 unless defined($new_problem->{problem_version});

is_deeply($updated_problem, $deleted_problem, "deleteSetProblem: delete one problem in an existing set.");

done_testing;

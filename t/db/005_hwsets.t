#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of problem sets.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use feature "say";
use Text::CSV qw/csv/;
use List::MoreUtils qw(uniq);
use Test::More;
use Test::Exception;
use Try::Tiny;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;

use Array::Utils qw/array_minus intersect/;
use DateTime::Format::Strptime;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs filterBySetType loadSchema/;

my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?"
	unless (-e $config_file);

my $config = LoadFile($config_file);

my $schema =
	DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# $schema->storage->debug(1);  # print out the SQL commands.

my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs      = $schema->resultset("Course");
my $user_rs        = $schema->resultset("User");

# load HW sets from CSV file
my @hw_sets = loadCSV("$main::ww3_dir/t/db/sample_data/hw_sets.csv");
for my $hw_set (@hw_sets) {
	$hw_set->{set_type}    = "HW";
	$hw_set->{set_version} = 1 unless defined($hw_set->{set_version});
	$hw_set->{set_params} = {} unless defined $hw_set->{set_params};

}

my @quizzes = loadCSV("$main::ww3_dir/t/db/sample_data/quizzes.csv");
for my $set (@quizzes) {
	$set->{set_type}    = "QUIZ";
	$set->{set_version} = 1 unless defined($set->{set_version});
	$set->{set_params} = {} unless defined $set->{set_params};

}

my @review_sets = loadCSV("$main::ww3_dir/t/db/sample_data/review_sets.csv");
for my $set (@review_sets) {
	$set->{set_type}    = "REVIEW";
	$set->{set_version} = 1 unless defined($set->{set_version});
	$set->{set_params} = {} unless defined $set->{set_params};

}

my @all_problem_sets = (@hw_sets,@quizzes,@review_sets);

## Test getting all problem sets

my @problem_sets_from_db = $problem_set_rs->getAllProblemSets;

@problem_sets_from_db = sort { $a->{set_name} cmp $b->{set_name} } @problem_sets_from_db;
@all_problem_sets     = sort { $a->{set_name} cmp $b->{set_name} } @all_problem_sets;

## remove the id tags:
for my $set (@problem_sets_from_db) {
	removeIDs($set);
	delete $set->{visible};    # remove information about the course
	delete $set->{course_dates};
}

is_deeply(\@all_problem_sets, \@problem_sets_from_db, "getProblemSets: get all sets");

# filter the precalculus sets:
my @precalc_sets = filterBySetType(\@all_problem_sets, undef, "Precalculus");

## make a clone of the sets:
my $all_precalc_sets = clone(\@precalc_sets);

for my $set (@$all_precalc_sets) {
	delete $set->{course_name};
}

## test for all sets in one course

my @all_precalc_sets = sort { $a->{set_name} cmp $b->{set_name} } @$all_precalc_sets;

my @precalc_sets_from_db = $problem_set_rs->getProblemSets({ course_name => "Precalculus" });

# remove id tags:
for my $set (@precalc_sets_from_db) {
	removeIDs($set);
}

is_deeply(\@all_precalc_sets, \@precalc_sets_from_db, "getProblemSets: get sets for one course");

## test all HW sets in one course

my @precalc_hw = filterBySetType(\@all_problem_sets, "HW", "Precalculus");
@precalc_hw = map {
	{%$_};
} @precalc_hw;    # make a clone

for my $set (@precalc_hw) {
	delete $set->{course_name};
}
@precalc_hw = sort { $a->{set_name} cmp $b->{set_name} } @precalc_hw;
my @precalc_hw_from_db = $problem_set_rs->getHWSets({ course_name => "Precalculus" });

# remove id tags:
for my $set (@precalc_hw_from_db) {
	removeIDs($set);
}

is_deeply(\@precalc_hw, \@precalc_hw_from_db, "getHWSets: get all homework for one course");

## get one Problem set

my $set_one     = $precalc_hw[0];
my $set_from_db = $problem_set_rs->getProblemSet({ course_name => "Precalculus", set_name => $set_one->{set_name} });
removeIDs($set_from_db);
is_deeply($set_one, $set_from_db, "getProblemSet: get one homework");

## get a problem set that doesn't exist.

throws_ok {
	$problem_set_rs->getProblemSet({ course_name => "Precalculus", set_name => "nonexistent_set" });
}
"DB::Exception::SetNotInCourse", "getProblemSet: non-existent set name";

throws_ok {
	$problem_set_rs->getProblemSet({ course_name => "Precalculus", set_id => 99999 });
}
"DB::Exception::SetNotInCourse", "getProblemSet: non-existent set_id";

## try to get a problem set that is not in a given course

throws_ok {
	$problem_set_rs->getProblemSet({ course_name => "Precalculus", set_id => 6 });
}
"DB::Exception::SetNotInCourse", "getProblemSet: find a set that is not in a course";

## add a new problem set

my $new_set_params = {
	set_name  => "HW #9",
	set_dates => { open => 100, reduced_scoring => 120, due => 140, answer => 200 },
	set_type  => "HW"
};

my $new_set    = $problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set_params);

my $new_set_id = $new_set->{set_id};
removeIDs($new_set);
delete $new_set->{type};

is_deeply($new_set_params, $new_set, "addProblemSet: add one homework");

## try to add a homework without set_name

my $new_set2 = {
	name      => "HW #11",
	set_dates => { open => 100, due => 140, answer => 200 },
	set_type  => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set2);
}
"DB::Exception::ParametersNeeded", "addProblemSet: set_name not passed in.";

## try to add a homework with bad date fields

my $new_set3 = {
	set_name  => "HW #11",
	set_dates => { open_set => 100, due => 140, answer => 200 },
	set_type  => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set3);
}
"DB::Exception::InvalidDateField", "addProblemSet: invalid date field passed in.";

## try to add a homework set without all required date fields

my $new_set4 = {
	set_name  => "HW #11",
	set_dates => { open => 100, due => 140 },
	set_type  => "HW"
};

throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set4);
}
"DB::Exception::RequiredDateFields", "addProblemSet: missing required date fields";

## try to add a homework set without all required date fields

my $new_set5 = {
	set_name  => "HW #11",
	set_dates => { open => 100, due => 140, answer => "1234s" },
	set_type  => "HW"
};
throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set5);
}
"DB::Exception::InvalidDateFormat", "addProblemSet: adding a non-numeric date";

## try to add a homework set without invalid date order

my $new_set6 = {
	set_name   => "HW #11",
	set_dates  => { open => 100, due => 140, answer => 10 },
	set_type   => "HW",
	set_params => {}
};
throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set6);
}
"DB::Exception::ImproperDateOrder", "addProblemSet: adding an illegal date order.";

## check for undefined parameter fields

my $new_set7 = {
	set_name   => "HW #11",
	set_dates  => { open => 100, due => 140, answer => 200 },
	set_type   => "HW",
	set_params => { enable_reduced_scoring => 0, not_a_valid_field => 5 }
};

throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set7);
}
"DB::Exception::UndefinedParameter", "addProblemSet: adding an undefined parameter field";

## check for invalid parameter fields

my $new_set8 = {
	set_name   => "HW #11",
	set_dates  => { open => 100, due => 140, answer => 200 },
	set_type   => "HW",
	set_params => { enable_reduced_scoring => 0, hide_hint => "yes" }
};
throws_ok {
	$problem_set_rs->addProblemSet({ course_name => "Precalculus" }, $new_set8);
}
"DB::Exception::InvalidParameter", "addProblemSet: adding an non-valid parameter";

## update a set

$new_set_params->{set_name}    = "HW #8";
$new_set_params->{set_params}  = { enable_reduced_scoring => 1 };
$new_set_params->{type}        = 1;
$new_set_params->{set_version} = 1;

my $updated_set = $problem_set_rs->updateProblemSet({ course_name => "Precalculus", set_id => $new_set_id },
	{ set_name => $new_set_params->{set_name}, set_params => { enable_reduced_scoring => 1 } });
removeIDs($updated_set);
delete $updated_set->{set_visible};
delete $new_set_params->{type};

is_deeply($new_set_params, $updated_set, "updateSet: change the set parameters");

## update the set where the set_type is sent, but the type is not:

$new_set_params->{set_name} = "HW #88";
$new_set_params->{set_type} = "HW";
delete $new_set_params->{type};

$updated_set =
	$problem_set_rs->updateProblemSet({ course_name => "Precalculus", set_id => $new_set_id }, $new_set_params);

removeIDs($updated_set);
delete $updated_set->{set_visible};
is_deeply($new_set_params, $updated_set, "updateSet: update a set with set_type defined.");

## try to update a set with an illegal field

throws_ok {
	$problem_set_rs->updateProblemSet({ course_name => "Precalculus", set_id => $new_set_id }, { bad_field => 0 });
}
"DBIx::Class::Exception", "updateProblemSet: use a non-existing field";

## try to update a set with an illegal date field

throws_ok {
	$problem_set_rs->updateProblemSet({ course_name => "Precalculus", set_id => $new_set_id },
		{ set_dates => { bad_date => 99 } });
}
"DB::Exception::InvalidDateField", "updateSet: invalid date field passed in.";

## try to update a set with an dates in a bad order

throws_ok {
	$problem_set_rs->updateProblemSet({ course_name => "Precalculus", set_id => $new_set_id },
		{ set_dates => { open => 999, answer => 100 } });
}
"DB::Exception::ImproperDateOrder", "updateSet: adding an illegal date order.";

## delete a set

my $deleted_set = $problem_set_rs->deleteProblemSet({ course_name => "Precalculus", set_name => "HW #88" });
removeIDs($deleted_set);
delete $deleted_set->{set_visible};

is_deeply($new_set_params, $deleted_set, "deleteProblemSet: delete a set");

done_testing;

1;

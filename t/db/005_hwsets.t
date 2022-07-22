#!/usr/bin/env perl

# This tests the basic database CRUD functions of problem sets.

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
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
use DateTime::Format::Strptime;
use Mojo::JSON qw/true false/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs filterBySetType/;

# Load the database
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# $schema->storage->debug(1);  # print out the SQL commands.

my $problem_set_rs = $schema->resultset('ProblemSet');
my $course_rs      = $schema->resultset('Course');
my $user_rs        = $schema->resultset('User');

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

# Test getting all problem sets
my @all_problem_sets = (@hw_sets, @quizzes, @review_sets);

# clone the sets since we need the original sets for the end of the test.
@all_problem_sets = @{ clone \@all_problem_sets };

my @problem_sets_from_db = $problem_set_rs->getAllProblemSets;

@problem_sets_from_db = sort { $a->{set_name} cmp $b->{set_name} } @problem_sets_from_db;
@all_problem_sets     = sort { $a->{set_name} cmp $b->{set_name} } @all_problem_sets;

# Remove the id tags
for my $set (@problem_sets_from_db) {
	removeIDs($set);
	# Remove information about the course
	delete $set->{visible};
	delete $set->{course_dates};
}

is_deeply(\@all_problem_sets, \@problem_sets_from_db, 'getProblemSets: get all sets');

# Filter the precalculus sets:
my @precalc_sets = filterBySetType(\@all_problem_sets, undef, 'Precalculus');

# Make a clone of the sets:
my $all_precalc_sets = clone(\@precalc_sets);

for my $set (@$all_precalc_sets) {
	delete $set->{course_name};
}

# Test for all sets in one course

my @all_precalc_sets = sort { $a->{set_name} cmp $b->{set_name} } @$all_precalc_sets;

my @precalc_sets_from_db = $problem_set_rs->getProblemSets(info => { course_name => 'Precalculus' });

# Remove id tags
for my $set (@precalc_sets_from_db) {
	removeIDs($set);
}

is_deeply(\@all_precalc_sets, \@precalc_sets_from_db, 'getProblemSets: get sets for one course');

# Test all HW sets in one course
my @precalc_hw = filterBySetType(\@all_problem_sets, 'HW', 'Precalculus');
for my $set (@precalc_hw) {
	delete $set->{course_name};
}
@precalc_hw = sort { $a->{set_name} cmp $b->{set_name} } @precalc_hw;
my @precalc_hw_from_db = $problem_set_rs->getHWSets(info => { course_name => 'Precalculus' });

# Remove id tags
for my $set (@precalc_hw_from_db) {
	removeIDs($set);
}
is_deeply(\@precalc_hw, \@precalc_hw_from_db, 'getHWSets: get all homework for one course');

# Get one Problem set
my $set_one = $precalc_hw[0];
my $set_from_db =
	$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => $set_one->{set_name} });
removeIDs($set_from_db);
is_deeply($set_one, $set_from_db, 'getProblemSet: get one homework');

# Get a problem set that doesn't exist.
throws_ok {
	$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => 'nonexistent_set' });
}
'DB::Exception::SetNotInCourse', 'getProblemSet: non-existent set name';

throws_ok {
	$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_id => 99999 });
}
'DB::Exception::SetNotInCourse', 'getProblemSet: non-existent set_id';

# Try to get a problem set that is not in a given course
throws_ok {
	$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_id => 6 });
}
'DB::Exception::SetNotInCourse', 'getProblemSet: find a set that is not in a course';

# Add a new problem set
my $new_set_params = {
	set_name  => "HW #9",
	set_dates => {
		open                   => 100,
		reduced_scoring        => 120,
		due                    => 140,
		answer                 => 200,
		enable_reduced_scoring => true
	},
	set_type => "HW"
};

my $new_set = $problem_set_rs->addProblemSet(
	params => {
		course_name => 'Precalculus',
		%$new_set_params
	}
);
my $new_set_id = $new_set->{set_id};
removeIDs($new_set);
delete $new_set->{type};
# add the default set_visible
$new_set_params->{set_visible} = false;
is_deeply($new_set_params, $new_set, "addProblemSet: add one homework");

# Try to add a homework without set_name
my $new_set2 = {
	name      => 'HW #11',
	set_dates => { open => 100, due => 140, answer => 200 },
	set_type  => 'HW'
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set2
		}
	);
}
'DB::Exception::ParametersNeeded', 'addProblemSet: set_name not passed in.';

# Try to add a homework with bad date fields
my $new_set3 = {
	set_name  => 'HW #11',
	set_dates => { open_set => 100, due => 140, answer => 200 },
	set_type  => 'HW'
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set3
		}
	);
}
'DB::Exception::InvalidDateField', 'addProblemSet: invalid date field passed in.';

# Try to add a homework set without all required date fields
my $new_set4 = {
	set_name  => 'HW #11',
	set_dates => { open => 100, due => 140 },
	set_type  => 'HW'
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set4
		}
	);
}
'DB::Exception::RequiredDateFields', 'addProblemSet: missing required date fields';

# Try to add a homework set without all required date fields
my $new_set5 = {
	set_name  => 'HW #11',
	set_dates => { open => 100, due => 140, answer => '1234s' },
	set_type  => 'HW'
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set5
		}
	);
}
'DB::Exception::InvalidDateFormat', 'addProblemSet: adding a non-numeric date';

# Try to add a homework set without invalid date order
my $new_set6 = {
	set_name   => 'HW #11',
	set_dates  => { open => 100, due => 140, answer => 10 },
	set_type   => 'HW',
	set_params => {}
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set6
		}
	);
}
'DB::Exception::ImproperDateOrder', 'addProblemSet: adding an illegal date order.';

# Check for undefined parameter fields
my $new_set7 = {
	set_name   => 'HW #11',
	set_dates  => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
	set_type   => 'HW',
	set_params => { not_a_valid_field => 5 }
};
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_set7
		}
	);
}
'DB::Exception::UndefinedParameter', 'addProblemSet: adding an undefined parameter field';

# Check for invalid parameter fields (the hide_hint param is a boolean)
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			set_name    => 'HW #11',
			set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
			set_type    => 'HW',
			set_params  => { hide_hint => 'yes' }
		}
	);
}
'DB::Exception::InvalidParameter', 'addProblemSet: adding an non-valid parameter';

# Check to ensure true/false are passed into the set_params, not 0/1
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			set_name    => 'HW #11',
			set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
			set_type    => 'HW',
			set_params  => { hide_hint => 0 }
		}
	);
}
'DB::Exception::InvalidParameter', 'addProblemSet: adding an non-valid boolean parameter';

# Check to ensure true/false are passed into the enable_reduced_scoring in set_dates, not 0/1
throws_ok {
	$problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			set_name    => 'HW #11',
			set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => 0 },
			set_type    => 'HW',
			set_params  => { hide_hint => 0 }
		}
	);
}
'DB::Exception::InvalidParameter', 'addProblemSet: adding an non-valid boolean parameter in set_dates';

# Update a set
$new_set_params->{set_name}   = "HW #8";
$new_set_params->{set_params} = { hide_hint => true };
$new_set_params->{type}       = 1;

my $updated_set = $problem_set_rs->updateProblemSet(
	info => {
		course_name => 'Precalculus',
		set_id      => $new_set_id
	},
	params => {
		set_name   => $new_set_params->{set_name},
		set_params => {
			hide_hint => true
		}
	}
);
removeIDs($updated_set);
delete $new_set_params->{type};
is_deeply($new_set_params, $updated_set, 'updateSet: change the set parameters');

# Update the set where the set_type is sent, but the type is not:
$new_set_params->{set_name}    = 'HW #88';
$new_set_params->{set_type}    = 'HW';
$new_set_params->{set_visible} = true;
delete $new_set_params->{type};
$updated_set = $problem_set_rs->updateProblemSet(
	info   => { course_name => 'Precalculus', set_id => $new_set_id },
	params => $new_set_params
);

removeIDs($updated_set);
is_deeply($new_set_params, $updated_set, "updateSet: update a set with set_type defined.");

# Change the type of a problem set from a Homework Set to a Quiz.

my $set_with_new_type_params = clone($new_set_params);
$set_with_new_type_params->{set_dates}  = { open => 0, answer => 0, due => 0 };
$set_with_new_type_params->{set_params} = {};
$set_with_new_type_params->{set_type}   = 'QUIZ';

my $set_with_new_type = $problem_set_rs->updateProblemSet(
	info   => { course_name => 'Precalculus', set_id => $new_set_id },
	params => { set_type    => 'QUIZ' }
);
removeIDs($set_with_new_type);

is_deeply($set_with_new_type, $set_with_new_type_params, 'updateSet: change the type of the problem set');

# Try to update a set with an illegal field
throws_ok {
	$problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_id => $new_set_id },
		params => { bad_field   => 0 }
	);
}
'DBIx::Class::Exception', 'updateProblemSet: use a non-existing field';

# Try to update a set with an illegal date field
throws_ok {
	$problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_id => $new_set_id },
		params => { set_dates   => { bad_date => 99 } }
	);
}
'DB::Exception::InvalidDateField', 'updateSet: invalid date field passed in.';

# Try to update a set with an dates in a bad order
throws_ok {
	$problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_id => $new_set_id },
		params => {
			set_dates => {
				open   => 999,
				answer => 100
			}
		}
	);
}
'DB::Exception::ImproperDateOrder', 'updateSet: adding an illegal date order.';

# Delete a set
my $deleted_set = $problem_set_rs->deleteProblemSet(info => { course_name => 'Precalculus', set_name => 'HW #88' });
removeIDs($deleted_set);
is_deeply($set_with_new_type_params, $deleted_set, 'deleteProblemSet: delete a set');

# Try deleting a set with invalid course_name
throws_ok {
	$problem_set_rs->deleteProblemSet(
		info => {
			course_name => 'Not a course',
			set_name    => 'HW #1'
		}
	);
}
'DB::Exception::CourseNotFound', 'deleteCourse: try to delete a set from a not existent course.';

# Try deleting a set that does not exist
throws_ok {
	$problem_set_rs->deleteProblemSet(
		info => {
			course_name => 'Precalculus',
			set_name    => 'HW #99'
		}
	);
}
'DB::Exception::SetNotInCourse', 'deleteCourse: try to delete a set that not exist.';

# ensure that the problem_sets table in the database is restored.
@all_problem_sets     = (@hw_sets, @quizzes, @review_sets);
@problem_sets_from_db = $problem_set_rs->getAllProblemSets;

@all_problem_sets     = sort { $a->{set_name} cmp $b->{set_name} } @all_problem_sets;
@problem_sets_from_db = sort { $a->{set_name} cmp $b->{set_name} } @problem_sets_from_db;

# Remove the id tags
for my $set (@problem_sets_from_db) {
	removeIDs($set);
	# Remove information that is returned about the course.
	delete $set->{visible};
	delete $set->{course_dates};
	# delete $set->{course_name};
}

is_deeply(\@all_problem_sets, \@problem_sets_from_db, 'check: ensure that the problem_sets table is restored.');

done_testing;

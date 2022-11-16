#!/usr/bin/env perl

# This tests the basic database CRUD functions of problem sets.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/encode_json decode_json true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/addCourses addSets/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'problem sets' => sub ($schema) {
	# Add the neccessary sample data to the database.
	addCourses($schema, $ww3_dir);
	addSets($schema, $ww3_dir);

	my $problem_set_rs = $schema->resultset('ProblemSet');

	# Onle the precalculus sets are needed for this test.
	my (@precalc_sets, @precalc_hw);

	# Load HW sets from JSON file.
	my $course_hw_sets = decode_json($ww3_dir->child('t/db/sample_data/hw_sets.json')->slurp);
	my @hw_sets;
	for my $course_data (@$course_hw_sets) {
		next unless $course_data->{course_name} eq 'Precalculus';
		for my $hw_set (@{ $course_data->{sets} }) {
			$hw_set->{set_type} = 'HW';
			push(@precalc_sets, $hw_set);
			push(@precalc_hw,   $hw_set);
		}
	}

	# Load quiz sets from JSON file.
	my $course_quizzes = decode_json($ww3_dir->child('t/db/sample_data/quizzes.json')->slurp);
	my @quizzes;
	for my $course_data (@$course_quizzes) {
		next unless $course_data->{course_name} eq 'Precalculus';
		for my $quiz (@{ $course_data->{sets} }) {
			$quiz->{set_type} = 'QUIZ';
			push(@precalc_sets, $quiz);
		}
	}

	# Load review sets from JSON file.
	my $course_review_sets = decode_json($ww3_dir->child('t/db/sample_data/review_sets.json')->slurp);
	my @review_sets;
	for my $course_data (@$course_review_sets) {
		next unless $course_data->{course_name} eq 'Precalculus';
		for my $review_set (@{ $course_data->{sets} }) {
			$review_set->{set_type} = 'REVIEW';
			push(@precalc_sets, $review_set);
		}
	}

	@precalc_sets = sort { $a->{set_name} cmp $b->{set_name} } @precalc_sets;
	@precalc_hw   = sort { $a->{set_name} cmp $b->{set_name} } @precalc_hw;

	# Get all sets in one course.
	my @precalc_sets_from_db = $problem_set_rs->getProblemSets(info => { course_name => 'Precalculus' });
	removeIDs($_) for @precalc_sets_from_db;
	is(\@precalc_sets_from_db, \@precalc_sets, 'getProblemSets: get sets for one course');

	# Get all HW sets in one course.
	my @precalc_hw_from_db = $problem_set_rs->getHWSets(info => { course_name => 'Precalculus' });
	removeIDs($_) for @precalc_hw_from_db;
	is(\@precalc_hw_from_db, \@precalc_hw, 'getHWSets: get all homework for one course');

	# Get one problem set.
	my $set_from_db =
		$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => $precalc_hw[0]{set_name} });
	removeIDs($set_from_db);
	is($set_from_db, $precalc_hw[0], 'getProblemSet: get one homework');

	# Get a problem set that doesn't exist.
	is(
		dies {
			$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => 'nonexistent_set' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'getProblemSet: non-existent set name'
	);

	# Try to get a problem set that is not in a given course.
	is(
		dies { $problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_id => 7 }); },
		check_isa('DB::Exception::SetNotInCourse'),
		'getProblemSet: find a set that is not in a course'
	);

	# Add a new problem set.
	my $new_set_params = {
		set_name  => 'HW #9',
		set_dates => {
			open                   => 100,
			reduced_scoring        => 120,
			due                    => 140,
			answer                 => 200,
			enable_reduced_scoring => true
		},
		set_params => {},
		set_type   => 'HW'
	};

	my $new_set = $problem_set_rs->addProblemSet(params => { course_name => 'Precalculus', %$new_set_params });
	is(
		$new_set,
		hash {
			field set_id      => match qr/^\d*$/;
			field course_id   => match qr/^\d*$/;
			field set_name    => $new_set_params->{set_name};
			field set_dates   => $new_set_params->{set_dates};
			field set_params  => $new_set_params->{set_params};
			field set_type    => $new_set_params->{set_type};
			field set_visible => false;
			end;
		},
		'addProblemSet: add one homework'
	);

	# Try to add a homework without set_name
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					name        => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 200 },
					set_type    => 'HW'
				}
			);
		},
		check_isa('DB::Exception::ParametersNeeded'),
		'addProblemSet: set_name not passed in.'
	);

	# Try to add a homework with bad date fields.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open_set => 100, due => 140, answer => 200 },
					set_type    => 'HW'
				}
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'addProblemSet: invalid date field passed in.'
	);

	# Try to add a homework set without all required date fields.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140 },
					set_type    => 'HW'
				}
			);
		},
		check_isa('DB::Exception::FieldsNeeded'),
		'addProblemSet: missing required date fields'
	);

	# Try to add a homework set without all required date fields
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => '1234s' },
					set_type    => 'HW'
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addProblemSet: adding a non-numeric date'
	);

	# Try to add a homework set without invalid date order
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 10 },
					set_type    => 'HW',
					set_params  => {}
				}
			);
		},
		check_isa('DB::Exception::ImproperDateOrder'),
		'addProblemSet: adding an illegal date order.'
	);

	# Check for undefined parameter fields
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
					set_type    => 'HW',
					set_params  => { not_a_valid_field => 5 }
				}
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'addProblemSet: adding an undefined parameter field'
	);

	# Check for invalid parameter fields (the hide_hint param is a boolean)
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
					set_type    => 'HW',
					set_params  => { hide_hint => 'yes' }
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addProblemSet: adding an non-valid parameter'
	);

	# Check to ensure true/false are passed into the set_params, not 0/1
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => false },
					set_type    => 'HW',
					set_params  => { hide_hint => 0 }
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addProblemSet: adding an non-valid boolean parameter'
	);

	# Check to ensure true/false are passed into the enable_reduced_scoring in set_dates, not 0/1
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_name    => 'HW #11',
					set_dates   => { open => 100, due => 140, answer => 200, enable_reduced_scoring => 0 },
					set_type    => 'HW',
					set_params  => { hide_hint => 0 }
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addProblemSet: adding an non-valid boolean parameter in set_dates'
	);

	# Update a set
	$new_set_params->{set_name}   = 'HW #8';
	$new_set_params->{set_params} = { hide_hint => true };

	my $updated_set = $problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus',               set_id     => $new_set->{set_id} },
		params => { set_name    => $new_set_params->{set_name}, set_params => $new_set_params->{set_params} }
	);
	is(
		$updated_set,
		hash {
			field set_id      => $new_set->{set_id};
			field course_id   => match qr/^\d*$/;
			field set_name    => $new_set_params->{set_name};
			field set_dates   => $new_set_params->{set_dates};
			field set_params  => $new_set_params->{set_params};
			field set_type    => $new_set_params->{set_type};
			field set_visible => false;
			end;
		},
		'updateSet: change the set parameters'
	);

	# Update a set where the set_type is sent, but the type is not.
	$new_set_params->{set_name}    = 'HW #88';
	$new_set_params->{set_type}    = 'HW';
	$new_set_params->{set_visible} = true;
	$updated_set                   = $problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_id => $new_set->{set_id} },
		params => $new_set_params
	);

	removeIDs($updated_set);
	is($updated_set, $new_set_params, 'updateSet: update a set with set_type defined.');

	# Change the type of a problem set from a Homework Set to a Quiz.
	$new_set_params->{set_dates}  = { open => 0, answer => 0, due => 0 };
	$new_set_params->{set_params} = {};
	$new_set_params->{set_type}   = 'QUIZ';

	my $set_with_new_type = $problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_id => $new_set->{set_id} },
		params => { set_type    => 'QUIZ' }
	);
	removeIDs($set_with_new_type);

	is($set_with_new_type, $new_set_params, 'updateSet: change the type of the problem set');

	# Try to update a set with an illegal field
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_id => $new_set->{set_id} },
				params => { bad_field   => 0 }
			);
		},
		check_isa('DBIx::Class::Exception'),
		'updateProblemSet: use a non-existing field'
	);

	# Try to update a set with an illegal date field
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_id => $new_set->{set_id} },
				params => { set_dates   => { bad_date => 99 } }
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'updateSet: invalid date field passed in.'
	);

	# Try to update a set with an dates in a bad order
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_id => $new_set->{set_id} },
				params => { set_dates   => { open => 999, answer => 100 } }
			);
		},
		check_isa('DB::Exception::ImproperDateOrder'),
		'updateSet: adding an illegal date order.'
	);

	# Delete a set
	my $deleted_set =
		$problem_set_rs->deleteProblemSet(
			info => { course_name => 'Precalculus', set_name => $new_set_params->{set_name} });
	removeIDs($deleted_set);
	is($deleted_set, $new_set_params, 'deleteProblemSet: delete a set');

	# Try deleting a set with invalid course_name
	is(
		dies {
			$problem_set_rs->deleteProblemSet(info => { course_name => 'Not a course', set_name => 'HW #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'deleteCourse: try to delete a set from a not existent course.'
	);

	# Try deleting a set that does not exist
	is(
		dies {
			$problem_set_rs->deleteProblemSet(info => { course_name => 'Precalculus', set_name => 'HW #99' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'deleteCourse: try to delete a set that not exist.'
	);
};

done_testing;

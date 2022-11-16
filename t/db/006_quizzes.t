#!/usr/bin/env perl

# This tests the basic database CRUD functions of problem sets of type quiz.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;
use Mojo::JSON qw/decode_json true false/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use BuildDB qw/addCourses addSets/;
use DBSubtest qw/dbSubtest/;
use TestUtils qw/removeIDs/;

my $ww3_dir = curfile->dirname->dirname->dirname;

dbSubtest 'course users' => sub ($schema) {
	# Add the neccessary sample data to the database.
	addCourses($schema, $ww3_dir);
	addSets($schema, $ww3_dir);

	my $problem_set_rs = $schema->resultset('ProblemSet');

	# Load quiz sets from JSON file
	my $course_quizzes = decode_json($ww3_dir->child('t/db/sample_data/quizzes.json')->slurp);
	my @quizzes;
	for my $course (@$course_quizzes) {
		for my $quiz (@{ $course->{sets} }) {
			$quiz->{set_type}    = 'QUIZ';
			$quiz->{course_name} = $course->{course_name};
			push(@quizzes, $quiz);
		}
	}

	# Remove 'Quiz #9' if it exists
	my $quiz_to_delete = $problem_set_rs->find({ set_name => 'Quiz #9' });
	$quiz_to_delete->delete if defined($quiz_to_delete);

	# Test getting all quizzes from one course
	my @precalc_quizzes = grep { $_->{set_type} eq 'QUIZ' && $_->{course_name} eq 'Precalculus' } @quizzes;
	for my $quiz (@precalc_quizzes) {
		delete $quiz->{course_name};
	}
	@precalc_quizzes = sort { $a->{set_name} cmp $b->{set_name} } @precalc_quizzes;
	my @precalc_quizzes_from_db = $problem_set_rs->getQuizzes(info => { course_name => 'Precalculus' });

	# Remove id tags
	for my $quiz (@precalc_quizzes_from_db) {
		removeIDs($quiz);
	}
	is(\@precalc_quizzes_from_db, \@precalc_quizzes, 'getQuizzes: get all quizzes for one course');

	# Get a single quiz
	my $quiz_from_db =
		$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => 'Quiz #1' });
	removeIDs($quiz_from_db);
	my @quiz_from_json = grep { $_->{set_name} eq 'Quiz #1' } @precalc_quizzes;
	delete $quiz_from_json[0]->{type};
	is($quiz_from_db, $quiz_from_json[0], 'getQuiz: get one quiz from a single course');

	# Try to get a quiz that doesn't exist in a course that does.
	is(
		dies {
			$problem_set_rs->getProblemSet(info => { course_name => 'Precalculus', set_name => 'nonexisent quiz' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'getQuiz: non-existent set name'
	);

	# Try to get a quiz from a course that doesn't exist.
	is(
		dies {
			$problem_set_rs->getProblemSet(info => { course_name => 'nonexistent course', set_name => 'Quiz #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'getQuiz: try to get a quiz from a non-existent course'
	);

	# Add a new quiz
	my $new_quiz_params = {
		set_name   => 'Quiz #9',
		set_dates  => { open => 100, due => 140, answer => 200 },
		set_params => {},
		set_type   => 'QUIZ'
	};

	my $new_quiz = $problem_set_rs->addProblemSet(
		params => {
			course_name => 'Precalculus',
			%$new_quiz_params
		}
	);

	removeIDs($new_quiz);
	# add the default set_visible field
	$new_quiz_params->{set_visible} = false;
	is($new_quiz, $new_quiz_params, "addQuiz: add a new quiz");

	# Try to add a quiz to a non existent course.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => { course_name => 'nonexistent course', set_name => 'Quiz #1' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'addQuiz: try to add a quiz from a non-existent course'
	);

	# Try to add a quiz with non-valid parameters.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name       => 'Precalculus',
					set_type          => 'QUIZ',
					set_name          => 'Quiz #99',
					nonexistent_field => 1,
				}
			)
		},
		check_isa('DBIx::Class::Exception'),
		'addQuiz: try to add a quiz with a bad parameter'
	);

	# Try to add a quiz without specifying the name.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => { course_name => 'Precalculus', set_type => 'QUIZ', set_visible => true, });
		},
		check_isa('DB::Exception::ParametersNeeded'),
		'addQuiz: try to add a quiz with a bad field'
	);

	# Try to add a quiz with an undefined parameter.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_type    => 'QUIZ',
					set_name    => 'Quiz #99',
					set_visible => true,
					set_params  => { param1 => 0 },
					set_dates   => { open   => 10, due => 100, answer => 200, }
				}
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'addQuiz: try to add a quiz with a undefined parameter'
	);

	# Try to add a quiz with a non-valid parameter.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_type    => 'QUIZ',
					set_name    => 'Quiz #99',
					set_visible => true,
					set_params  => { timed => 'yes' },
					set_dates   => { open  => 10, due => 100, answer => 200, }
				}
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'addQuiz: try to add a quiz with a non-valid parameter'
	);

	# Try to add a quiz with a missing required date fields.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_type    => 'QUIZ',
					set_name    => 'Quiz #99',
					set_dates   => { open => 10, due => 100 }
				}
			);
		},
		check_isa('DB::Exception::FieldsNeeded'),
		'addQuiz: try to add a quiz with a missing required date fields'
	);

	# Try to add a quiz with an undefined date field.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_type    => 'QUIZ',
					set_name    => 'Quiz #99',
					set_visible => 1,
					set_dates   => { open => 10, due => 100, answer => 200, reduced_scoring => 300 }
				}
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'addQuiz: try to add a quiz with an undefined date field'
	);

	# Try to add a quiz with dates that are out of order.
	is(
		dies {
			$problem_set_rs->addProblemSet(
				params => {
					course_name => 'Precalculus',
					set_type    => 'QUIZ',
					set_name    => 'Quiz #99',
					set_visible => 1,
					set_dates   => { open => 10, due => 300, answer => 200, }
				}
			);
		},
		check_isa('DB::Exception::ImproperDateOrder'),
		'addQuiz: try to add a quiz with dates that are out of order'
	);
	# Update the visibility of the quiz
	my $updated_params = { set_visible => 0 };
	my $updated_quiz   = $problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
		params => $updated_params
	);

	$new_quiz->{set_visible} = false;
	$new_quiz->{set_params}  = {};
	removeIDs($updated_quiz);
	is($updated_quiz, $new_quiz, 'updateQuiz: successfully update the quiz');

	# Update the params of the quiz
	$updated_params = { set_params => { timed => true } };
	$updated_quiz   = $problem_set_rs->updateProblemSet(
		info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
		params => $updated_params
	);
	removeIDs($updated_quiz);
	$new_quiz->{set_params} = { timed => true };
	is($updated_quiz, $new_quiz, 'updateQuiz: successfully update the params of the quiz');

	# Update the dates of the quiz
	$updated_params = { set_dates => { open => 400, due => 500, answer => 600 } };
	$updated_quiz   = $problem_set_rs->updateProblemSet(
		info => {
			course_name => 'Precalculus',
			set_name    => 'Quiz #9'
		},
		params => $updated_params
	);
	removeIDs($updated_quiz);
	$new_quiz->{set_dates} = $updated_params->{set_dates};
	is($updated_quiz, $new_quiz, 'updateQuiz: successfully update the dates of the quiz');

	# Try to update a non-existent field of the quiz.
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name       => 'Precalculus', set_name => 'Quiz #9' },
				params => { nonexistent_field => 1 }
			);
		},
		check_isa('DBIx::Class::Exception'),
		'updateQuiz: try to update a quiz with a non-valid field'
	);

	# Try to update a non-existent param of the quiz.
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
				params => { set_params  => { show_hint => 1 } }
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'updateQuiz: try to update a quiz with an undefined parameter'
	);

	# Try to update a parameter with a bad value
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
				params => { set_params  => { timed => 'yes' } }
			);
		},
		check_isa('DB::Exception::InvalidParameter'),
		'updateQuiz: try to update a quiz with a non-valid field'
	);

	# Try to update a quiz with an invalid  date
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
				params => { set_dates   => { reduced_scoring => 1000 } }
			);
		},
		check_isa('DB::Exception::InvalidField'),
		'updateQuiz: try to update a quiz with a non-valid date'
	);

	# Try to update a quiz with a date out of order.
	is(
		dies {
			$problem_set_rs->updateProblemSet(
				info   => { course_name => 'Precalculus', set_name => 'Quiz #9' },
				params => { set_dates   => { open => 50, due => 40 } }
			);
		},
		check_isa('DB::Exception::ImproperDateOrder'),
		'updateQuiz: try to update a quiz with out of order dates'
	);

	# Try to delete from a non-existent course.
	is(
		dies {
			$problem_set_rs->deleteProblemSet(
				info => { course_name => 'Course does not exist', set_name => 'Quiz #9' });
		},
		check_isa('DB::Exception::CourseNotFound'),
		'deleteQuiz: try to delete a quiz from a non-existent course'
	);

	# Try to delete from a non-existent course.
	is(
		dies { $problem_set_rs->deleteProblemSet(info => { course_id => 9999, set_name => 'Quiz #9' }); },
		check_isa('DB::Exception::CourseNotFound'),
		'deleteQuiz: try to delete a quiz from a non-existent course_id'
	);

	# Try to delete from a non-existent set in a course.
	is(
		dies {
			$problem_set_rs->deleteProblemSet(info => { course_name => 'Precalculus', set_name => 'Quiz #999' });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'deleteQuiz: try to delete a non-existent quiz'
	);

	# Try to delete from a non-existent set in a course.
	is(
		dies {
			$problem_set_rs->deleteProblemSet(info => { course_name => 'Precalculus', set_id => 99999 });
		},
		check_isa('DB::Exception::SetNotInCourse'),
		'deleteQuiz: try to delete a non-existent quiz as set_id'
	);

	# Try to delete from a non-existent set in a  course:
	my $deleted_quiz = $problem_set_rs->deleteProblemSet(
		info => {
			course_name => 'Precalculus',
			set_name    => 'Quiz #9'
		}
	);
	removeIDs($deleted_quiz);
	is($deleted_quiz, $new_quiz, 'delete Quiz: successfully delete a quiz');
};

done_testing;

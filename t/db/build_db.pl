#!/usr/bin/env perl

# 
# this file builds a sqlite database file based on a csv file
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
use Carp;
use JSON; 

use DB::WithParams;
use DB::WithDates;

use DB::Schema; 
use DB; 
use DB::TestUtils qw/loadCSV/; 




# set up the database
my $db_file = "$main::test_dir/sample_db.sqlite";


## first delete the file
unlink $db_file; 

my $schema = DB::Schema->connect("dbi:SQLite:$db_file");
if (not -e $db_file) {
    $schema->deploy();  ## create the database based on the schema
}

my $course_rs = $schema->resultset('Course');
my $user_rs = $schema->resultset('User');
my $course_user_rs = $schema->resultset('CourseUser');
my $problem_set_rs = $schema->resultset('ProblemSet');
my $problem_pool_rs = $schema->resultset('ProblemPool');

sub addUsers {
	# add some users

	my @all_students = loadCSV("$main::test_dir/sample_data/students.csv");

	for my $student (@all_students) {
		# dd $student; 
		my $course = $course_rs->find_or_create({course_name => $student->{course_name}});
		my $stud_info = {};
		for my $key (qw/login first_name last_name email student_id/) {
			$stud_info->{$key} = $student->{$key};
		}
		$course->add_to_users($stud_info);

		my $user = $user_rs->find({login => $student->{login}});
		my $params = {user_id=> $user->user_id, course_id=> $course->course_id};
		my $course_user = $course_user_rs->find($params);
		for my $key (qw/section recitation params role/) {
			$params->{$key} = $student->{$key};
		}
		my $u = $course_user->update($params);
	}
	return;
}

my @hw_dates = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES;
my @hw_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS; 

my @quiz_dates = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES; 
my @quiz_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS; 


sub addSets {
	## add some problem sets
	my @hw_sets = loadCSV("$main::test_dir/sample_data/hw_sets.csv");
	for my $set (@hw_sets) {
		my $course = $course_rs->search({course_name => $set->{course_name}})->single; 
		if (! defined($course)){
			croak "The course ". $set->{course_name} ." does not exist"; 
		}
		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}

	## add quizzes

	my @quizzes = loadCSV("$main::test_dir/sample_data/quizzes.csv");
	for my $quiz (@quizzes) {
		my $course = $course_rs->search({course_name => $quiz->{course_name}})->single; 
		if (! defined($course)){
			croak "The course ". $quiz->{course_name} ." does not exist"; 
		}
		$quiz->{type} = 2;
		delete $quiz->{course_name};
		$course->add_to_problem_sets($quiz);
	}

	my @review_sets = loadCSV("$main::test_dir/sample_data/review_sets.csv");
	for my $set (@review_sets) {
		my $course = $course_rs->find({course_name => $set->{course_name}}); 
		croak "The course |$set->{course_name}| does not exist" unless defined($course);

		$set->{type} = 4;
		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}


	return;
}

sub addProblems {
	## add some problems 
	my @problems = loadCSV("$main::test_dir/sample_data/problems.csv");
	for my $prob (@problems){
		# check if the course_name/set_name exists
		my $set = $problem_set_rs->search(
				{
					'me.set_name' => $prob->{set_name}, 
					'courses.course_name' => $prob->{course_name}
				},
				{
					join => 'courses'
				}
			)->single; 
		croak "The course |$set->{course_name}| with set name |$set->{name}| is not defined" unless defined($set);
		delete $prob->{course_name};
		delete $prob->{set_name};
		
		$prob->{problem_number} = int($prob->{problem_number});
		
		## the following isn't working.   Perhaps because it is the result of a join
		# $sets[0]->add_to_problems->($prob);
		my $problem_set = $problem_set_rs->search({set_id => $set->set_id})->single;

		$problem_set->add_to_problems($prob);

	}
	return;
}

sub addUserSets {
	## add some users to problem sets
	my @user_sets = loadCSV("$main::test_dir/sample_data/user_sets.csv");
	for my $user_set (@user_sets){
		# check if the course_name/set_name/user_name exists
		my $course = $course_rs->find({ course_name=>$user_set->{course_name}});
		my $user_course = $course->users->find({login=>$user_set->{login}});
		if( defined $user_course) {
			my $problem_set = $schema->resultset('ProblemSet')->find({ course_id => $course->course_id, set_name => $user_set->{set_name} });
			for my $key (qw/course_name set_name login/) { 
				delete $user_set->{$key};
			}
			# for my $key (qw/answer_date open_date reduced_scoring_date due_date/) {
			# 	delete $user_set->{$key} unless $user_set->{$key}; 
			# }
			$user_set->{user_id} = $user_course->user_id;
			$user_set->{set_id} = $problem_set->set_id; 
			$problem_set->add_to_user_sets($user_set);
		}
	}
	return;
}

sub addProblemPools {
	my @problem_pools = loadCSV("$main::test_dir/sample_data/pool_problems.csv");
	for my $pool (@problem_pools) {
		my $course = $course_rs->find({ course_name=>$pool->{course_name}});
		croak "The course |$pool->{course_name}| does not exist" unless defined($course);

		my $prob_pool = $problem_pool_rs->find_or_create({course_id => $course->course_id, pool_name => $pool->{pool_name}});
		$prob_pool->add_to_pool_problems({library_id => $pool->{library_id}});

		
	}
}


addUsers;
addSets;
addProblems;
addUserSets;
addProblemPools;

# my $u = $course_user_rs->find({course_id=>1,user_id=>5});
# dd {$u->get_columns}; 


1; 
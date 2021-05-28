#!/usr/bin/env perl

# 
# this file builds a sqlite database file based on a csv file
#
use warnings;
use strict;

use lib "../../lib";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use Text::Table;
use Carp;

use DB::Schema; 
use DB; 

# set up the database
my $db_file = "sample_db.sqlite";


## first delete the file
unlink $db_file; 

my $schema = DB::Schema->connect("dbi:SQLite:$db_file");
if (not -e $db_file) {
    $schema->deploy();  ## create the sqlite database based on the schema
}

my $course_rs = $schema->resultset('Course');
my $user_rs = $schema->resultset('User');
my $course_user_rs = $schema->resultset('CourseUser');

sub addUsers {
	# add some users

	my $students = csv (in => "students.csv", headers => "lc", blank_is_undef => 1);

	for my $student (@$students) {
		my $course = $course_rs->find_or_create({course_name => $student->{course_name}});
		my $stud_info = {};
		for my $key (qw/login first_name last_name email student_id/) {
			$stud_info->{$key} = $student->{$key};
		}
		$course->add_to_users($stud_info);

		my $user = $user_rs->find({login => $student->{login}});
		my $params = {user_id=> $user->user_id, course_id=> $course->course_id};
		my $course_user = $course_user_rs->find($params);
		for my $key (qw/section recitation comment roles/) {
			$params->{$key} = $student->{$key};
		}
		$course_user->update($params);
	}
	return;
}

my @problem_set_params = qw/timed time_length/; 

sub addSets {
	## add some problem sets
	my $sets = csv(in => "problem_sets.csv", headers => "lc", blank_is_undef => 1);
	for my $set (@$sets) {
		$set->{params} = {};
		for my $param (@problem_set_params){
			$set->{params}->{$param} = $set->{$param} if defined($set->{$param});
			delete $set->{$param};
		}
		# dd $sets; 
		my $course = $schema->resultset('Course')->search({course_name => $set->{course_name}})->single; 
		if (! defined($course)){
			croak "The course ". $set->{course_name} ." does not exist"; 
		}
		delete $set->{course_name};
		$course->add_to_problem_sets($set);
	}
	return;
}

sub addProblems {
	## add some problems 
	my $problems = csv(in => "problems.csv", headers => "lc", blank_is_undef => 1);
	for my $prob (@$problems){
		# check if the course_name/set_name exists
		my $set = $schema->resultset('ProblemSet')->search(
				{
					'me.set_name' => $prob->{set_name}, 
					'courses.course_name' => $prob->{course_name}
				},
				{
					join => 'courses'
				}
			)->single; 
		if (! defined($set)){
			croak "The course ". $set->{course_name} ." with set name " . $set->{set_name} . " is not defined"; 
		}
		delete $prob->{course_name};
		delete $prob->{set_name};
		
		$prob->{problem_number} = int($prob->{problem_number});
		
		## the following isn't working.   Perhaps because it is the result of a join
		# $sets[0]->add_to_problems->($prob);
		my $problem_set = $schema->resultset('ProblemSet')->search({set_id => $set->set_id})->single;

		$problem_set->add_to_problems($prob);

	}
	return;
}

sub addUserSets {
	## add some users to problem sets
	my $user_sets = csv(in => "user_sets.csv", headers => "lc", blank_is_undef => 1);
	for my $user_set (@$user_sets){
		# check if the course_name/set_name/user_name exists
		my $course = $schema->resultset('Course')->find({ course_name=>$user_set->{course_name}});
		my $user_course = $course->users->find({login=>$user_set->{login}});
		if( defined $user_course) {
			my $problem_set = $schema->resultset('ProblemSet')->find({ course_id => $course->course_id, set_name => $user_set->{set_name} });
			for my $key (qw/course_name set_name login/) { 
				delete $user_set->{$key};
			}
			for my $key (qw/answer_date open_date reduced_scoring_date due_date/) {
				delete $user_set->{$key} unless $user_set->{$key}; 
			}
			$user_set->{user_id} = $user_course->user_id;
			$user_set->{set_id} = $problem_set->set_id; 
			$problem_set->add_to_user_sets($user_set);
		}
	}
	return;
}


addUsers;
addSets;
addProblems;
addUserSets;

# # get column names for the Album table
# my @cols   = $schema->resultset("User")->result_source->columns;

# # create header with these column names
# my $table  = Text::Table->new( header( @cols ) );

# @rows = $schema->resultset('User')->find({ login=>"homer" })->courses; 

# for my $row (@rows) {
# 	# $table->add( map { $row->get_column($_)} @cols);
# 	dd $row->get_columns;
# }

# # print $table;


1; 
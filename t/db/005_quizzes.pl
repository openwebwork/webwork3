# 
# This tests the basic database CRUD functions of problem sets. 
#
use warnings;
use strict;

use lib "../../lib";

use Text::CSV qw/csv/;
use Data::Dump qw/dd/;
use List::MoreUtils qw(uniq);
use Test::More; 
use Test::Exception;
use Clone qw/clone/;

use Array::Utils qw/array_minus intersect/;

use DB::Schema; 

# load the database
my $db_file = "sample_db.sqlite";
my $schema = DB::Schema->connect("dbi:SQLite:$db_file");
# $schema->storage->debug(1);  # print out the SQL commands. 


my @hw_dates = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES; 
my @hw_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS; 

my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs = $schema->resultset("Course");
my $user_rs = $schema->resultset("User");

my @all_problem_sets;   # stores all problem_sets

loadSetsFromCSV();


## test: get all quizzes from one course
my @precalc_quizzes = filterBySetType(\@all_problem_sets,"QUIZ","Precalculus");
@precalc_quizzes = cloneSets(\@precalc_quizzes);

for my $quiz (@precalc_quizzes) {
	delete $quiz->{course_name};
}
@precalc_quizzes = sort {$a->{name} cmp $b->{name}} @precalc_quizzes;
my @precalc_quizzes_from_db = $problem_set_rs->getQuizzes({course_name => "Precalculus"});


# remove id tags:
for my $quiz (@precalc_quizzes_from_db){
	removeIDs($quiz); 
}

is_deeply(\@precalc_quizzes,\@precalc_quizzes_from_db,"getQuizzes: get all quizzes for one course");


done_testing;

## helpful subroutines

sub removeIDs {  # remove any field that ends in _id
	my $obj = shift;
	for my $key (keys %$obj){
		delete $obj->{$key} if $key =~ /_id$/; 
	}
}

sub cloneSets {
	my $sets = clone(shift);
	return @$sets; 
}

sub buildHash {
	my ($hash,$param_names,$name) = @_; 
	my $new_hash = {}; 
	for my $param (@$param_names) {
		$new_hash->{$param} = $hash->{$param} if defined($hash->{$param});
	}
	return $new_hash; 
}

## This takes the array (as arrayref) of all problem sets in all courses, and filters by 
## set type, course name or both



sub filterBySetType {
	my ($all_sets,$type,$course_name) = @_; 

	my $type_hash = $DB::Schema::ResultSet::ProblemSet::SET_TYPES;

	my @filtered_sets = @$all_sets; 

	if (defined($course_name)){
		@filtered_sets = grep { $_->{course_name} eq $course_name } @filtered_sets; 
	}
	if (defined($type)){
		@filtered_sets = grep { $_->{type} eq $type_hash->{$type} } @filtered_sets; 
	}

	return @filtered_sets;
}

sub loadSetsFromCSV {
	# load the csv file:
	my $hw_sets_from_csv = csv (in => "sample_data/hw_sets.csv", headers => "lc", blank_is_undef => 1);
	

	## load HW sets
	for my $set (@$hw_sets_from_csv) {
		my $hw_set = {
			name => $set->{name},
			course_name => $set->{course_name},
			type => 1, # this is the type number for a "HW"
			params => buildHash($set,\@hw_params,"params"),
			dates => buildHash($set,\@hw_dates,"dates")
		};
		push(@all_problem_sets,$hw_set);
	}

	## load Quizzes

	my $quizzes_from_csv = csv (in => "sample_data/quizzes.csv", headers => "lc", blank_is_undef => 1);
	for my $quiz (@$quizzes_from_csv) {
		my $quiz2 = {
			name => $quiz->{name},
			course_name => $quiz->{course_name},
			type => 2, # this is the type number for a "QUIZ"
			params => buildHash($quiz,\@hw_params,"params"),
			dates => buildHash($quiz,\@hw_dates,"dates")
		};
		push(@all_problem_sets,$quiz2);
	}
}

1;

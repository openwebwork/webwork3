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
use Carp; 

use Array::Utils qw/array_minus intersect/;

use DB::Schema; 
use DB::CSVUtils qw/loadCSV/; 

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

my @quizzes = loadCSV("sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{type} = 2; 
}


## test: get all quizzes from one course
my @precalc_quizzes = filterBySetType(\@quizzes,"QUIZ","Precalculus");
@precalc_quizzes = cloneSets(\@precalc_quizzes);

for my $quiz (@precalc_quizzes) {
	delete $quiz->{course_name};
}
@precalc_quizzes = sort {$a->{set_name} cmp $b->{set_name}} @precalc_quizzes;
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


1;

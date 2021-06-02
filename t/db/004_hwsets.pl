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

## Test getting all problem sets


my @problem_sets_from_db = $problem_set_rs->getAllProblemSets; 

## remove the id tags:
for my $set (@problem_sets_from_db){
	removeIDs($set);
}

is_deeply(\@all_problem_sets,\@problem_sets_from_db,"getProblemSets: get all sets");

## test for all sets in one course

# filter the precalculus sets:
my @precalc_sets = filterBySetType(\@all_problem_sets,undef,"Precalculus");
@precalc_sets = cloneSets(\@precalc_sets);

for my $set (@precalc_sets) {
	delete $set->{course_name};
}
@precalc_sets = sort {$a->{name} cmp $b->{name}} @precalc_sets; 


my @precalc_sets_from_db = $problem_set_rs->getProblemSets({course_name => "Precalculus"});
# remove id tags:
for my $set (@precalc_sets_from_db){
	removeIDs($set);
}

is_deeply(\@precalc_sets,\@precalc_sets_from_db,"getProblemSets: get sets for one course");

## test all HW sets in one course

my @precalc_hw = filterBySetType(\@all_problem_sets,"HW","Precalculus");
@precalc_hw = cloneSets(\@precalc_hw);

for my $set (@precalc_hw) {
	delete $set->{course_name};
}
@precalc_hw = sort {$a->{name} cmp $b->{name}} @precalc_hw; 
my @precalc_hw_from_db = $problem_set_rs->getHWSets({course_name => "Precalculus"});


# remove id tags:
for my $set (@precalc_hw_from_db){
	removeIDs($set);
}


is_deeply(\@precalc_hw,\@precalc_hw_from_db,"getHWSets: get all homework for one course");

## get one Problem set

my $set_one = $precalc_hw[0];
my $set_from_db = $problem_set_rs->getProblemSet({course_name=>"Precalculus",name=>$set_one->{name}});
removeIDs($set_from_db); 



## get a problem set that doesn't exist.

dies_ok {
	$problem_set_rs->getProblemSet({course_name => "Precalculus", name => "nonexistent_set"});
} "getProblemSet: non-existent set name";
dies_ok {
	$problem_set_rs->getProblemSet({course_name => "Precalculus", set_id => 99999});
} "getProblemSet: non-existent set_id";


is_deeply($set_one,$set_from_db,"getProblemSet: get one homework");


## add a new problem set

my $new_set_params = {
	name => "HW #9",
	dates => {open => 100, reduced_scoring => 120, due=> 140, answer => 200},
	set_type => "HW"
};

my $new_set = $problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set_params);
removeIDs($new_set); 

is_deeply($new_set_params,$new_set,"addProblemSet: add one homework"); 

## try to add a homework set with bad date fields

my $new_set2 = {
	name => "HW #11",
	dates => {open_set => 100,  due=> 140, answer => 200},
	set_type => "HW"
};

dies_ok {
	$problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set2);
} "addProblemSet: illegal date field";

## try to add a homework set without all required date fields

my $new_set3 = {
	name => "HW #11",
	dates => {open => 100,  due=> 140},
	set_type => "HW"
};

dies_ok {
	$problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set3);
} "addProblemSet: not all required date fields";

## try to add a homework set without all required date fields

my $new_set4 = {
	name => "HW #11",
	dates => {open => 100,  due=> 140, answer => "1234s"},
	set_type => "HW"
};
dies_ok {
	$problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set4);
} "addProblemSet: adding a non-numeric date";


## try to add a homework set without invalid param fields

my $new_set5 = {
	name => "HW #11",
	dates => {open => 100,  due=> 140, answer => 200},
	set_type => "HW",
	params => {has_reduced_scoring => 0, not_a_valid_field => 5}
};
dies_ok {
	$problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set5);
} "addProblemSet: adding an non-valid parameter";

## validate the parameters

my $new_set6 = {
	name => "HW #11",
	dates => {open => 100,  due=> 140, answer => 200},
	set_type => "HW",
	params => {visible => 0, hide_hints => "no"}
};
dies_ok {
	$problem_set_rs->addProblemSet({course_name => "Precalculus"},$new_set6);
} "addProblemSet: adding an non-valid parameter";


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
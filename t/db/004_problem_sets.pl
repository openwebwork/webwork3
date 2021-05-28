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

use DB::Schema; 


# load the database
my $db_file = "sample_db.sqlite";
my $schema = DB::Schema->connect("dbi:SQLite:$db_file");
# $schema->storage->debug(1);  # print out the SQL commands. 

# load the csv file:
my $sets_from_csv = csv (in => "problem_sets.csv", headers => "lc", blank_is_undef => 1);

# move some fields into a params field
for my $set (@$sets_from_csv) {
	$set->{params} = {};
	for my $key (qw/timed time_length/) {
		$set->{params}->{$key} = $set->{$key} if defined $set->{$key};
		delete $set->{$key}; 
	}
}



my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs = $schema->resultset("Course");
my $user_rs = $schema->resultset("User");

## Test getting all problem sets

my @all_problem_sets = $problem_set_rs->getProblemSets; 

## remove the id tags:
for my $set (@all_problem_sets){
	for my $key (qw/course_id set_id/){
		delete $set->{$key};
	}
}

is_deeply($sets_from_csv,\@all_problem_sets,"getProblemSets: get all sets");

# filter the precalculus sets:
my @precalc_sets = grep { $_->{course_name} eq "Precalculus" } @$sets_from_csv;
for my $set (@precalc_sets) {
	delete $set->{course_name};
}
@precalc_sets = sort {$a->{set_name} cmp $b->{set_name}} @precalc_sets; 



my @precalc_sets_from_db = $course_rs->getProblemSets({course_name => "Precalculus"});
# remove id tags:
for my $set (@precalc_sets_from_db){
	for my $key (qw/course_id set_id/){
		delete $set->{$key};
	}
}

is_deeply(\@precalc_sets,\@precalc_sets_from_db,"getProblemSets: get sets for one course");

done_testing;
1;
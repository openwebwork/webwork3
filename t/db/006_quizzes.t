#
# This tests the basic database CRUD functions of problem sets of type quiz.
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
use Test::More;
use Test::Exception;
use YAML::XS qw/LoadFile/;

use Array::Utils qw/array_minus intersect/;
use DateTime::Format::Strptime;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs filterBySetType/;

# load some configuration for the database:

my $config = LoadFile("$main::lib_dir/../conf/webwork3.yml");

my $schema;
# load the database
if ($config->{database} eq 'sqlite') {
	$schema  = DB::Schema->connect($config->{sqlite_dsn});
} elsif ($config->{database} eq 'mariadb') {
	$schema  = DB::Schema->connect($config->{mariadb_dsn},$config->{database_user},$config->{database_password});
}

my $strp = DateTime::Format::Strptime->new( pattern => '%FT%T',on_error  => 'croak' );

# $schema->storage->debug(1);  # print out the SQL commands.

my @hw_dates  = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES;
my @hw_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS;

my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs      = $schema->resultset("Course");
my $user_rs        = $schema->resultset("User");

my @all_problem_sets;    # stores all problem_sets

my @quizzes = loadCSV("$main::test_dir/sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{type}     = 2;
	$quiz->{set_type} = "QUIZ";
	for my $date (keys %{$quiz->{dates}}) {
		my $dt = $strp->parse_datetime( $quiz->{dates}->{$date});
		$quiz->{dates}->{$date} = $dt->epoch;
	}
}

## test: get all quizzes from one course
my @precalc_quizzes = filterBySetType( \@quizzes, "QUIZ", "Precalculus" );
@precalc_quizzes = map {
	{%$_};
} @precalc_quizzes;      # clone all quizzes

for my $quiz (@precalc_quizzes) {
	delete $quiz->{course_name};
}
@precalc_quizzes = sort { $a->{set_name} cmp $b->{set_name} } @precalc_quizzes;
my @precalc_quizzes_from_db = $problem_set_rs->getQuizzes( { course_name => "Precalculus" } );

# remove id tags:
for my $quiz (@precalc_quizzes_from_db) {
	removeIDs($quiz);
}

is_deeply( \@precalc_quizzes, \@precalc_quizzes_from_db, "getQuizzes: get all quizzes for one course" );

done_testing;

## helpful subroutines

1;

#
# This tests the basic database CRUD functions of problem sets.
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
use List::MoreUtils qw(uniq);
use Test::More;
use Test::Exception;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use Array::Utils qw/array_minus intersect/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs filterBySetType loadSchema/;

my $schema = loadSchema();

# $schema->storage->debug(1);  # print out the SQL commands.

my @hw_dates  = @DB::Schema::Result::ProblemSet::HWSet::VALID_DATES;
my @hw_params = @DB::Schema::Result::ProblemSet::HWSet::VALID_PARAMS;

my $problem_set_rs = $schema->resultset("ProblemSet");
my $course_rs      = $schema->resultset("Course");
my $user_rs        = $schema->resultset("User");

# load HW sets from CSV file
my @hw_sets = loadCSV("$main::test_dir/sample_data/hw_sets.csv");
for my $set (@hw_sets) {
	$set->{type}        = 1;
	$set->{set_type}    = "HW";
	$set->{set_version} = 1 unless defined( $set->{set_version} );
}

$problem_set_rs->newSetVersion( { course_id => 1, set_id => 1 } );

is_deeply( { test => 1 }, { test => 1 }, 'fake test' );

done_testing;

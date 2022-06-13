#!/usr/bin/env perl

use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path(dirname(__FILE__));
	$main::lib_dir  = dirname(dirname($main::test_dir)) . '/lib';
}

use lib "$main::lib_dir";

use Text::CSV qw/csv/;
use List::Util qw(uniq);
use Test::More;
use Test::Exception;
use Try::Tiny;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;
use DB::TestUtils qw/loadCSV removeIDs/;

# load the database
my $db_file = "$main::test_dir/sample_db.sqlite";
my $schema  = DB::Schema->connect("dbi:SQLite:$db_file");

my $course_user_rs = $schema->resultset('CourseUser');

my $u = $course_user_rs->find({ course_id => 1, user_id => 1 });

my $u2 = $u->get_inflated_columns;


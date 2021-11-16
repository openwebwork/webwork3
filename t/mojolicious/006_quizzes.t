#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use DateTime::Format::Strptime;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir = abs_path(dirname(__FILE__));
	$main::lib_dir  = dirname(dirname($main::test_dir)) . '/lib';
}

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions("perm" => \$TEST_PERMISSIONS);    # check for the flag --perm when running this.

use lib "$main::lib_dir";

use DB::Schema;
use DB::TestUtils qw/loadSchema loadCSV/;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
my $config = clone(LoadFile("$main::lib_dir/../conf/webwork3.yml"));

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# this tests the api with common courses routes

# load the database
my $schema = loadSchema();

my $t;

if ($TEST_PERMISSIONS) {
	$config->{ignore_permissions} = 1;
	$t = Test::Mojo->new(WeBWorK3 => $config);

	# username an admin
	$t->post_ok('/webwork3/api/username' => json => { email => 'admin@google.com', password => 'admin' })
		->status_is(200)->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)
		->json_is('/user/user_id' => 1)->json_is('/user/is_admin' => 1);

} else {
	$config->{ignore_permissions} = 0;
	$t = Test::Mojo->new(WeBWorK3 => $config);
}

# load the quizzes

my @quizzes = loadCSV("$main::lib_dir/../t/db/sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{set_type} = "QUIZ";
	for my $date (keys %{ $quiz->{dates} }) {
		my $dt = $strp->parse_datetime($quiz->{dates}->{$date});
		$quiz->{dates}->{$date} = $dt->epoch;
	}
}

$t->get_ok('/webwork3/api/courses/2/sets')->content_type_is('application/json;charset=UTF-8')
	->json_is('/3/set_name' => "Quiz #1");

done_testing();

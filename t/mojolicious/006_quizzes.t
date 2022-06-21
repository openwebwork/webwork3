#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use DateTime::Format::Strptime;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd            qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use DB::Schema;
use Clone         qw/clone/;
use YAML::XS      qw/LoadFile/;
use DB::TestUtils qw/loadCSV/;

# Test the api with common 'courses/sets' routes for quizzes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# Connect to the database.
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $t = Test::Mojo->new(WeBWorK3 => $config);

$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)->json_is('/user/user_id' => 1)
	->json_is('/user/is_admin' => 1);

# Load the quizzes.
my @quizzes = loadCSV("$main::ww3_dir/t/db/sample_data/quizzes.csv");
for my $quiz (@quizzes) {
	$quiz->{set_type} = 'QUIZ';
	for my $date (keys %{ $quiz->{dates} }) {
		my $dt = $strp->parse_datetime($quiz->{dates}->{$date});
		$quiz->{dates}->{$date} = $dt->epoch;
	}
}

$t->get_ok('/webwork3/api/courses/2/sets')->content_type_is('application/json;charset=UTF-8')
	->json_is('/3/set_name' => 'Quiz #1');

done_testing();

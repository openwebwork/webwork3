#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON qw/true false/;

use DateTime::Format::Strptime;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use DB::Schema;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
use TestUtils qw/loadCSV/;
use List::MoreUtils qw/firstval/;

# Test the api with common 'courses/sets' routes for quizzes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# Connect to the database.
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $t = Test::Mojo->new(WeBWorK3 => $config);

# Login as an user with instructor privileges in a course (Arithmetic; course_id: 4)
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Load the quizzes.
my @quizzes = loadCSV(
	"$main::ww3_dir/t/db/sample_data/quizzes.csv",
	{
		boolean_fields           => ['set_visible'],
		param_boolean_fields     => ['timed'],
		param_non_neg_int_fields => ['quiz_duration']
	}
);
for my $quiz (@quizzes) {
	$quiz->{set_type}   = "QUIZ";
	$quiz->{set_params} = {} unless defined($quiz->{set_params});
}

# Get all problem_sets
$t->get_ok('/webwork3/api/courses/4/sets')->content_type_is('application/json;charset=UTF-8');
my $all_problem_sets = $t->tx->res->json;

# find the first quiz in the course.

my $quiz1 = firstval { $_->{set_type} eq 'QUIZ' } @$all_problem_sets;

# test some things about this quiz
$t->get_ok("/webwork3/api/courses/4/sets/$quiz1->{set_id}")->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'Quiz #1');

# Test that booleans are returned correctly.

$quiz1 = $t->tx->res->json;
my $timed = $quiz1->{set_params}->{timed};
ok($timed, 'testing that timed compares to 1.');
is($timed, true, 'testing that timed compares to true');
ok(JSON::PP::is_bool($timed),           'testing that timed is a true or false');
ok(JSON::PP::is_bool($timed) && $timed, 'testing that timed is a true');

# Make a new quiz

my $new_quiz_params = {
	set_name   => 'Quiz #20',
	set_type   => 'QUIZ',
	set_params => {
		timed             => true,
		quiz_duration     => 30,
		problem_randorder => true
	},
	set_dates => {
		open   => 100,
		due    => 200,
		answer => 300
	}
};

$t->post_ok('/webwork3/api/courses/4/sets' => json => $new_quiz_params)
	->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Quiz #20')
	->json_is('/set_type' => 'QUIZ');
my $returned_quiz = $t->tx->res->json;

my $new_quiz          = $t->tx->res->json;
my $problem_randorder = $new_quiz->{set_params}->{problem_randorder};
ok($problem_randorder, 'testing that problem_randorder compares to 1.');
is($problem_randorder, true, 'testing that problem_randorder compares to true');
ok(JSON::PP::is_bool($problem_randorder),                       'testing that problem_randorder is a true or false');
ok(JSON::PP::is_bool($problem_randorder) && $problem_randorder, 'testing that problem_randorder is a true');

# Check that updating a boolean parameter is working:

$t->put_ok(
	"/webwork3/api/courses/4/sets/$returned_quiz->{set_id}" => json => {
		set_params => {
			problem_randorder => false
		}
	}
)->status_is(200);

my $updated_quiz = $t->tx->res->json;

$problem_randorder = $updated_quiz->{set_params}->{problem_randorder};
ok(!$problem_randorder, 'testing that hide_hint is falsy.');
is($problem_randorder, false, 'testing that problem_randorder compares to false');
ok(JSON::PP::is_bool($problem_randorder),                        'testing that problem_randorder is a true or false');
ok(JSON::PP::is_bool($problem_randorder) && !$problem_randorder, 'testing that problem_randorder is a false');

# delete the added quiz
$t->delete_ok("/webwork3/api/courses/4/sets/$returned_quiz->{set_id}")
	->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Quiz #20')
	->json_is('/set_type' => 'QUIZ');

done_testing();

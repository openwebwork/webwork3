#!/usr/bin/env perl
#
# This tests the basic database CRUD functions of attempts.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";
use lib "$main::ww3_dir/t/lib";

use Test::More;
use Test::Exception;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use DB::Schema;
use TestUtils qw/loadCSV removeIDs loadSchema/;
use DB::Utils qw/updateAllFields/;

# Set up the database.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);

my $config = LoadFile($config_file);

my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);
# $schema->storage->debug(1);  # print out the SQL commands.

my $user_problem_rs = $schema->resultset('UserProblem');
my $attempt_rs      = $schema->resultset('Attempt');

# Delete previously added attempts.
# Question: should we instead write a deleteAttempt method and delete at the end of the test?

my $attempts = $attempt_rs->search(
	{
		'courses.course_name'  => 'Precalculus',
		'users.username'       => 'homer',
		'problem_set.set_name' => 'HW #2'
	},
	{
		join => {
			user_problem => {
				user_sets => [
					{
						'course_users' => 'users'
					},
					{
						'problem_set' => 'courses'
					}
				]
			}
		}
	}
);

$attempts->delete_all;

# Add a few attempts for a give User Problem.

my $user_problem_info = {
	course_name    => 'Precalculus',
	username       => 'homer',
	set_name       => 'HW #2',
	problem_number => 3
};

my $attempt_params1 = {
	scores  => [ 0,   1,     1 ],
	answers => [ 'x', 'x^2', 'x^3' ]
};

my $attempt1 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params1 });
removeIDs($attempt1);

is_deeply($attempt_params1, $attempt1, 'addAttempt: add an attempt');

my $attempt_params2 = {
	scores  => [ 0,    1,      1 ],
	answers => [ '2x', '3x^2', '4x^3' ]
};

my $attempt2 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params2 });
removeIDs($attempt2);
is_deeply($attempt_params2, $attempt2, 'addAttempt: add another attempt');

my $attempt_params3 = {
	scores  => [ 0,     0,      0 ],
	answers => [ '-2x', '2x^2', '4x^3' ]
};

my $attempt3 = $attempt_rs->addAttempt(params => { %$user_problem_info, %$attempt_params3 });
removeIDs($attempt3);
is_deeply($attempt_params3, $attempt3, 'addAttempt: add yet another attempt');

my @all_attempts = $attempt_rs->getAttempts(info => $user_problem_info);
for my $attempt (@all_attempts) {
	removeIDs($attempt);
	delete $attempt->{comments};
}

is_deeply([ $attempt_params1, $attempt_params2, $attempt_params3 ],
	\@all_attempts, "getAttempts: get attempts for a user problem;");

done_testing;

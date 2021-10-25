#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Data::Dumper;
use DateTime::Format::Strptime;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::ww3_dir = abs_path(dirname(__FILE__)) . '/../..';
}

use lib "$main::ww3_dir/lib";

use Getopt::Long;
my $TEST_PERMISSIONS;
GetOptions("perm" => \$TEST_PERMISSIONS);    # check for the flag --perm when running this.


use DB::Schema;
use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
use DB::TestUtils qw/loadCSV/;

my $config;
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
if (-e $config_file) {
	$config = clone(LoadFile($config_file));
	$config->{database_dsn} = $config->{test_database_dsn};
	$config->{database_user} = $config->{test_database_user};
	$config->{database_password} = $config->{test_database_password};
} else {
	die "The file $config_file does not exist.  Did you make a copy of it from ww3-dev.dist.yml ?";
}

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# Test the api with common "sets" routes


# set up the database:
my $schema = DB::Schema->connect($config->{test_database_dsn}, $config->{test_database_user},
	$config->{test_database_password});

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

# load the homework sets

my @hw_sets = loadCSV("$main::ww3_dir/t/db/sample_data/hw_sets.csv");
for my $set (@hw_sets) {
	$set->{set_type} = "HW";
	for my $date (keys %{ $set->{dates} }) {
		my $dt = $strp->parse_datetime($set->{dates}->{$date});
		$set->{dates}->{$date} = $dt->epoch;
	}
}

$t->get_ok('/webwork3/api/courses/2/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/1/set_name' => $hw_sets[1]->{set_name})->json_is('/1/dates/open' => $hw_sets[1]->{dates}->{open});

# Pull out the id from the response
my $set_id = $t->tx->res->json('/2/set_id');

# Disabled for now until this is fixed.
$t->get_ok("/webwork3/api/courses/2/sets/$set_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name'   => $hw_sets[2]->{set_name})->json_is('/set_type' => $hw_sets[2]->{set_type})
	->json_is('/dates/open' => $hw_sets[2]->{dates}->{open});

# new problem set

my $new_set = {
	set_name => 'HW #9',
	dates    => {
		open   => 100,
		due    => 500,
		answer => 500
	},
};

$t->post_ok("/webwork3/api/courses/2/sets" => json => $new_set)->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #9')->json_is('/set_type' => 'HW')->json_is('/dates/answer' => 500);

my $new_set_id = $t->tx->res->json('/set_id');

$t->put_ok("/webwork3/api/courses/2/sets/$new_set_id" => json => { set_name => 'HW #11' })
	->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'HW #11');

## test for exceptions

# a set that is not in a course
$t->get_ok("/webwork3/api/courses/1/sets/6")->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# try to update a set not in a course

$t->put_ok("/webwork3/api/courses/1/sets/6" => json => { set_name => 'HW #99' })
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# try to add a set without a setname

my $another_new_set = { name => "this is the wrong field" };

$t->post_ok("/webwork3/api/courses/2/sets" => json => $another_new_set)
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# delete an existing set

$t->delete_ok("/webwork3/api/courses/2/sets/$new_set_id")->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #11');

# try to delete a set not in a course
$t->delete_ok("/webwork3/api/courses/1/sets/6")->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

if ($TEST_PERMISSIONS) {
	$t->post_ok("/webwork3/api/logout")->status_is(200)->json_is('/logged_in' => 0);
}

## check that a non_admin user has proper access.

my @all_users   = $schema->resultset("User")->getCourseUsers({ course_id => 1 });
my @instructors = grep { $_->{role} eq 'instructor' } @all_users;

if ($TEST_PERMISSIONS) {
	$t->post_ok("/webwork3/api/username" => json =>
			{ email => $instructors[0]->{email}, password => $instructors[0]->{username} })->status_is(200)
		->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1);

	$t->get_ok('/webwork3/api/courses/1/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8');

	# ->json_is('/0' => $all_users[0]->{first_name});

	# dd $t->tx->res->json;
}

done_testing;

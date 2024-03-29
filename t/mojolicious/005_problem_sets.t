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

# Test the api with common 'courses/sets' routes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');

# Connect to the database.
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);
my $t = Test::Mojo->new(WeBWorK3 => $config);

# Login as an instructor.  Lisa is an instructor in course_id: 4 (Arithmetic)
$t->post_ok('/webwork3/api/login' => json => { username => 'lisa', password => 'lisa' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => true)
	->json_is('/user/username' => 'lisa')->json_is('/user/is_admin' => false);

# Load the homework sets.
my @hw_sets = loadCSV(
	"$main::ww3_dir/t/db/sample_data/hw_sets.csv",
	{
		boolean_fields       => ['set_visible'],
		param_boolean_fields => [ 'enable_reduced_scoring', 'hide_hint' ]
	}
);
for my $set (@hw_sets) {
	$set->{set_type} = 'HW';
}

my @arith_hw = grep { $_->{course_name} eq 'Arithmetic' } @hw_sets;

$t->get_ok('/webwork3/api/courses/4/sets')->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/1/set_name'       => $arith_hw[1]->{set_name})
	->json_is('/1/set_dates/open' => $arith_hw[1]->{set_dates}->{open});

my $arith_hw_from_db = $t->tx->res->json;

# Extract the id from the response.
my $set_id = $t->tx->res->json('/2/set_id');

$t->get_ok("/webwork3/api/courses/4/sets/$set_id")->status_is(200)->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name'       => $hw_sets[2]->{set_name})->json_is('/set_type' => $hw_sets[2]->{set_type})
	->json_is('/set_dates/open' => $hw_sets[2]->{set_dates}->{open});

# Create a new problem set
my $new_set = {
	set_name  => 'HW #9',
	set_dates => {
		open   => 100,
		due    => 500,
		answer => 500
	},
};

$t->post_ok('/webwork3/api/courses/4/sets' => json => $new_set)->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #9')->json_is('/set_type' => 'HW')->json_is('/set_dates/answer' => 500);

my $new_set_id = $t->tx->res->json('/set_id');

# Check that set_visible is a JSON boolean
my $set_visible = $t->tx->res->json('/set_visible');
ok(!$set_visible, 'testing that set_visible is falsy');
is($set_visible, false, 'Test that set_visible compares to Mojo::JSON::false');
ok(JSON::PP::is_bool($set_visible),                  'Test that set_visible is a JSON boolean');
ok(JSON::PP::is_bool($set_visible) && !$set_visible, 'Test that set_visible is a JSON::false');

# Update the HW set.
$t->put_ok(
	"/webwork3/api/courses/4/sets/$new_set_id" => json => {
		set_name    => 'HW #11',
		set_visible => true
	}
)->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'HW #11');

$set_visible = $t->tx->res->json('/set_visible');
ok($set_visible, 'testing that set_visible is truthy');
is($set_visible, true, 'Test that set_visible compares to Mojo::JSON::true');
ok(JSON::PP::is_bool($set_visible),                 'Test that set_visible is a JSON boolean');
ok(JSON::PP::is_bool($set_visible) && $set_visible, 'Test that set_visible is a JSON:: true');

# get the first hw set in course:
my $hw1 = $arith_hw_from_db->[0];

# Test that booleans are returned correctly.
my $enabled = $hw1->{set_dates}->{enable_reduced_scoring};
ok($enabled, 'testing that enabled_reduced_scoring compares to 1.');
is($enabled, true, 'testing that enabled_reduced_scoring compares to Mojo::JSON::true');
ok(JSON::PP::is_bool($enabled), 'testing that enabled_reduced_scoring is a Mojo::JSON::true or Mojo::JSON::false');
ok(JSON::PP::is_bool($enabled) && $enabled, 'testing that enabled_reduced_scoring is a Mojo::JSON::true');

# Check that updating a boolean parameter is working:
$t->put_ok(
	"/webwork3/api/courses/4/sets/$new_set_id" => json => {
		set_params => { hide_hint => false }
	}
)->content_type_is('application/json;charset=UTF-8');

my $hw2       = $t->tx->res->json;
my $hide_hint = $hw2->{set_params}->{hide_hint};
ok(!$hide_hint, 'testing that hide_hint is falsy.');
is($hide_hint, false, 'testing that hide_hint compares to Mojo::JSON::false');
ok(JSON::PP::is_bool($hide_hint),                'testing that hide_hint is a Mojo::JSON::true or Mojo::JSON::false');
ok(JSON::PP::is_bool($hide_hint) && !$hide_hint, 'testing that hide_hint is a Mojo::JSON::false');

# Test for exceptions

# Try to get a set that is not in a course
$t->get_ok('/webwork3/api/courses/4/sets/99')->content_type_is('application/json;charset=UTF-8')
	->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# Try to update a set not in a course
$t->put_ok('/webwork3/api/courses/4/sets/99' => json => { set_name => 'HW #99' })
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::SetNotInCourse');

# Try to add a set without a setname.
my $another_new_set = { name => 'this is the wrong field' };
$t->post_ok('/webwork3/api/courses/4/sets' => json => $another_new_set)
	->content_type_is('application/json;charset=UTF-8')->json_is('/exception' => 'DB::Exception::ParametersNeeded');

# Some cleanup to restore the databse
# Delete an existing set.
$t->delete_ok("/webwork3/api/courses/4/sets/$new_set_id")->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'HW #11');

done_testing;

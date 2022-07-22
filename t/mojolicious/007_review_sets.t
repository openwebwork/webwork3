#!/usr/bin/env perl

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Mojo::JSON qw/true false/;

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
use DateTime::Format::Strptime;
use List::MoreUtils qw/firstval/;
use TestUtils qw/loadCSV/;

my $strp = DateTime::Format::Strptime->new(pattern => '%FT%T', on_error => 'croak');
# Test the api with common "users" routes.

# Load the config file.
my $config_file = "$main::ww3_dir/conf/ww3-dev.yml";
$config_file = "$main::ww3_dir/conf/ww3-dev.dist.yml" unless (-e $config_file);
my $config = clone(LoadFile($config_file));

# Connect to the database.
my $schema = DB::Schema->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password});

my $t = Test::Mojo->new(WeBWorK3 => $config);

$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)->json_is('/user/user_id' => 1)
	->json_is('/user/is_admin' => 1);

# Load the review sets from the CSV file
my @review_sets = loadCSV("$main::ww3_dir/t/db/sample_data/review_sets.csv");
for my $review_set (@review_sets) {
	$review_set->{set_type} = "REVIEW";
	for my $date (keys %{ $review_set->{dates} }) {
		my $dt = $strp->parse_datetime($review_set->{dates}->{$date});
		$review_set->{dates}->{$date} = $dt->epoch;
	}
}

# Get all problem_sets
$t->get_ok('/webwork3/api/courses/1/sets')->content_type_is('application/json;charset=UTF-8');
my $all_problem_sets = $t->tx->res->json;

# find the first review set in the course.
my $review_set1 = firstval { $_->{set_type} eq 'REVIEW' } @$all_problem_sets;

# test some things about this review set

$t->get_ok("/webwork3/api/courses/1/sets/$review_set1->{set_id}")->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_name' => 'Review #1');

# Test that booleans are returned correctly.

$review_set1 = $t->tx->res->json;
my $can_retake = $review_set1->{set_params}->{can_retake};
ok($can_retake, 'testing that can_retake compares to 1.');
is($can_retake, true, 'testing that can_retake compares to Mojo::JSON::true');
ok(JSON::PP::is_bool($can_retake),                'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
ok(JSON::PP::is_bool($can_retake) && $can_retake, 'testing that can_retake is a Mojo::JSON::true');

# Make a new quiz

my $new_review_set_params = {
	set_name   => 'Review #20',
	set_type   => 'REVIEW',
	set_params => {
		can_retake => true,
	},
	set_dates => {
		open   => 100,
		closed => 200
	}
};

$t->post_ok('/webwork3/api/courses/2/sets' => json => $new_review_set_params)
	->content_type_is('application/json;charset=UTF-8')->json_is('/set_name' => 'Review #20')
	->json_is('/set_type' => 'REVIEW');

$review_set1 = $t->tx->res->json;
$can_retake  = $review_set1->{set_params}->{can_retake};
ok($can_retake, 'testing that can_retake compares to 1.');
is($can_retake, true, 'testing that can_retake compares to Mojo::JSON::true');
ok(JSON::PP::is_bool($can_retake),                'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
ok(JSON::PP::is_bool($can_retake) && $can_retake, 'testing that can_retake is a Mojo::JSON::true');

# Check that updating a boolean parameter is working:

$t->put_ok(
	"/webwork3/api/courses/2/sets/$review_set1->{set_id}" => json => {
		set_params => {
			can_retake => false
		}
	}
)->content_type_is('application/json;charset=UTF-8');

my $updated_set = $t->tx->res->json;
$can_retake = $updated_set->{set_params}->{can_retake};
ok(!$can_retake, 'testing that can_retake is falsy.');
is($can_retake, false, 'testing that can_retake compares to Mojo::JSON::false');
ok(JSON::PP::is_bool($can_retake), 'testing that can_retake is a Mojo::JSON::true or Mojo::JSON::false');
ok(JSON::PP::is_bool($can_retake) && !$can_retake, 'testing that can_retake is a Mojo::JSON::false');

# delete the added review set
$t->delete_ok("/webwork3/api/courses/2/sets/$review_set1->{set_id}")->content_type_is('application/json;charset=UTF-8')
	->json_is('/set_type' => 'REVIEW')->json_is('/set_name' => 'Review #20');

done_testing();

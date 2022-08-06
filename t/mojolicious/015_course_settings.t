#!/usr/bin/env perl

# Testing the mojolicious routes that involve global and course settings.

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

use Clone qw/clone/;
use YAML::XS qw/LoadFile/;
use List::MoreUtils qw/firstval/;

use TestUtils qw/loadCSV removeIDs/;

# Load the config file.
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);

# the YAML true/false will be loaded a JSON booleans.
local $YAML::XS::Boolean = "JSON::PP";
my $config = clone(LoadFile($config_file));

my $t = Test::Mojo->new(WeBWorK3 => $config);

# Authenticate with the admin user.
$t->post_ok('/webwork3/api/login' => json => { username => 'admin', password => 'admin' })->status_is(200)
	->content_type_is('application/json;charset=UTF-8')->json_is('/logged_in' => 1)->json_is('/user/user_id' => 1)
	->json_is('/user/is_admin' => 1);

# Load the global settings from the file
my $global_settings_from_file = LoadFile("$main::ww3_dir/conf/course_settings.yml");

# Get the global/default settings

$t->get_ok('/webwork3/api/global-settings')->content_type_is('application/json;charset=UTF-8')->status_is(200);
my $global_settings_from_db = $t->tx->res->json;

# This is needed for later.
my $global_settings = clone($global_settings_from_db);

# Do some cleanup.
for my $setting (@$global_settings_from_db) {
	delete $setting->{setting_id};
	for my $key (qw/subcategory options doc/) {
		delete $setting->{$key} unless $setting->{$key};
	}
}

is_deeply($global_settings_from_db, $global_settings_from_file, 'test that the global settings are correct.');

# get a single global/default setting
$t->get_ok('/webwork3/api/global-setting/1')->content_type_is('application/json;charset=UTF-8')->status_is(200)
	->json_is('/setting_name'  => $global_settings_from_file->[0]->{setting_name})
	->json_is('/default_value' => $global_settings_from_file->[0]->{default_value})
	->json_is('/description'   => $global_settings_from_file->[0]->{description});

# Get all of the course settings for Arithmetic from the csv file:
my @course_settings = loadCSV("$main::ww3_dir/t/db/sample_data/course_settings.csv");

@course_settings = grep { $_->{course_name} eq 'Arithmetic' } @course_settings;

# pull out setting_name/value pairs
for my $setting (@course_settings) {
	$setting = {
		setting_name => $setting->{setting_name},
		value        => $setting->{setting_value}
	};
}

# Get all course settings for a course (Arithmetic- course_id: 4)

$t->get_ok('/webwork3/api/courses/4/settings')->content_type_is('application/json;charset=UTF-8')->status_is(200);
my $course_settings_from_db = $t->tx->res->json;
# pull out setting_name/value pairs
for my $setting (@$course_settings_from_db) {
	$setting = {
		setting_name => $setting->{setting_name},
		value        => $setting->{value}
	};
}

is_deeply($course_settings_from_db, \@course_settings, 'Ensure that the course settings are correct.');

# Update a course setting (enable_reduced_scoring)

my $reduced_scoring = firstval { $_->{setting_name} eq 'reduced_scoring_value' } @$global_settings;

$t->put_ok(
	"/webwork3/api/courses/4/settings/$reduced_scoring->{setting_id}" => json => {
		value => 0.5
	}
)->content_type_is('application/json;charset=UTF-8')->status_is(200)->json_is('/value' => 0.5);

$t->delete_ok("/webwork3/api/courses/4/settings/$reduced_scoring->{setting_id}")
	->content_type_is('application/json;charset=UTF-8')->status_is(200)->json_is('/value' => 0.5);

done_testing;

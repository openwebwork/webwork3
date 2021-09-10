#!/usr/bin/env perl
#
# This tests the basic database CRUD functions with course settings.
#
use warnings;
use strict;

BEGIN {
	use File::Basename qw/dirname/;
	use Cwd qw/abs_path/;
	$main::test_dir     = abs_path( dirname(__FILE__) );
	$main::webwork_home = dirname( dirname($main::test_dir) );
	$main::lib_dir      = "$main::webwork_home/lib";
}

use lib "$main::lib_dir";

use Data::Dump qw/dd/;
use List::MoreUtils qw(uniq);

use Test::More;
use Test::Exception;
use Try::Tiny;
use YAML::XS qw/LoadFile/;

use DB::WithParams;
use DB::WithDates;
use DB::Schema;

# use WeBWorK3::Utils::Settings qw/checkSettings/;
use WeBWorK3::Utils::Settings qw/getDefaultCourseSettings getDefaultCourseValues
	validateSettingsConfFile validateSingleCourseSetting validateSettingConfig
	isInteger isTimeString isTimeDuration isDecimal mergeCourseSettings/;

use DB::TestUtils qw/loadCSV removeIDs loadSchema/;

my $schema = loadSchema();

# $schema->storage->debug(1);  # print out the SQL commands.

# test for various types

ok( isInteger(0),     "check type: integer" );
ok( isInteger(100),   "check type: integer" );
ok( isInteger(-30),   "check type: integer" );
ok( !isInteger(0.5),  "check type: not an integer" );
ok( !isInteger(-2.5), "check type: not an integer" );

ok( isTimeString("1:59"),  "check type: 24-hour time string" );
ok( isTimeString("01:59"), "check type: 24-hour time string" );
ok( isTimeString("00:59"), "check type: 24-hour time string" );
ok( isTimeString("11:59"), "check type: 24-hour time string" );
ok( isTimeString("13:59"), "check type: 24-hour time string" );
ok( isTimeString("21:00"), "check type: 24-hour time string" );

ok( !isTimeString("24:59"), "check type: not a 24-hour time string" );
ok( !isTimeString("31:59"), "check type: not a 24-hour time string" );
ok( !isTimeString("23:69"), "check type: not a 24-hour time string" );

ok( isTimeDuration("2 days"),   "check type: time duration" );
ok( isTimeDuration("10 sec"),   "check type: time duration" );
ok( isTimeDuration("12 min"),   "check type: time duration" );
ok( isTimeDuration("24 hrs"),   "check type: time duration" );
ok( isTimeDuration("24 hours"), "check type: time duration" );
ok( isTimeDuration("1 week"),   "check type: time duration" );
ok( isTimeDuration("1 WEEK"),   "check type: time duration" );

ok( !isTimeDuration("-24 hrs"),  "check type: not a time duration" );
ok( !isTimeDuration("4 apples"), "check type: not a time duration" );

ok( isDecimal(0.3),    "check type: decimal" );
ok( isDecimal(3),      "check type: decimal" );
ok( isDecimal(-0.3),   "check type: decimal" );
ok( isDecimal("0.33"), "check type: decimal" );
ok( isDecimal("-.33"), "check type: decimal" );

ok( isDecimal("00.33"),  "check type: decimal" );
ok( !isDecimal("0-.33"), "check type: not a decimal" );
ok( !isDecimal("abc"),   "check type: not a decimal" );

## check that the configuration file is valid;

is( validateSettingsConfFile(), 1, "configuration file valid" );

### TODO: test to make sure that all of the checks for the course configurations work.

my $default_course_settings = getDefaultCourseSettings();

# check that each of the given course_setting types are both valid and invalid

my $valid_setting = {
	var      => "my_setting",
	doc      => "this is a setting",
	type     => "integer",
	category => "general",
	default  => 0
};

is( validateSettingConfig($valid_setting), 1, "course setting: valid setting" );

## check various parts of the setting;

throws_ok {
	validateSettingConfig(
		{   var      => "mySetting",
			doc      => "this is a setting",
			type     => "integer",
			category => "general",
			default  => 0
		}
	)
}
"DB::Exception::InvalidCourseField", "course setting: variable not in kebob case";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc3     => "this is a setting",
			type     => "integer",
			category => "general",
			default  => 0
		}
	)
}
"DB::Exception::InvalidCourseField", "course setting: course setting with illegal field";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			type     => "integer",
			category => "general",
			default  => 0
		}
	)
}
"DB::Exception::InvalidCourseField", "course setting: missing required field";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc      => "this is a setting",
			type     => "nonnegint",
			category => "general",
			default  => 0
		}
	)
}
"DB::Exception::InvalidCourseFieldType", "course setting: non valid course parameter type";

## validate settings

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc      => "this is a setting",
			type     => "time",
			category => "general",
			default  => "12:343"
		}
	)
}
"DB::Exception::InvalidCourseFieldType", "course setting: bad time string";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc      => "this is a setting",
			type     => "integer",
			category => "general",
			default  => "12.343"
		}
	)
}
"DB::Exception::InvalidCourseFieldType", "course setting: bad integer format";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc      => "this is a setting",
			type     => "time_duration",
			category => "general",
			default  => "-2 days"
		}
	)
}
"DB::Exception::InvalidCourseFieldType", "course setting: bad time duration format";

throws_ok {
	validateSettingConfig(
		{   var      => "my_setting",
			doc      => "this is a setting",
			type     => "decimal",
			category => "general",
			default  => "12:343"
		}
	)
}
"DB::Exception::InvalidCourseFieldType", "course setting: bad decimal format";

my $course_rs = $schema->resultset("Course");

# check that the default settings are working

#make a new course with no settings and compare to the default settings

my $new_course = $course_rs->addCourse( { course_name => "New Course" } );

my $default_course_values = getDefaultCourseValues();
my $new_course_info       = { course_id => $new_course->{course_id} };
my $course_settings       = $course_rs->getCourseSettings($new_course_info);

is_deeply( $course_settings, $default_course_values, "course settings: default course_settings" );

# set a single course setting in General

my $updated_general_setting = { general => { course_description => "This is my new course description" } };

my $updated_course_settings = $course_rs->updateCourseSettings( $new_course_info, $updated_general_setting );

my $current_course_values = mergeCourseSettings( $default_course_values, $updated_general_setting );

is_deeply( $current_course_values, $updated_course_settings, "course_settings: updated general setting" );

# update another general setting

$updated_general_setting = { general => { hardcopy_theme => "One Column" } };

$updated_course_settings = $course_rs->updateCourseSettings( $new_course_info, $updated_general_setting );

$current_course_values = mergeCourseSettings( $current_course_values, $updated_general_setting );

is_deeply( $current_course_values, $updated_course_settings, "course_settings: updated another general setting" );

# set a single course setting in Optional Modules

my $updated_optional_setting = { optional => { enable_show_me_another => 1 } };
$updated_course_settings = $course_rs->updateCourseSettings( $new_course_info, $updated_optional_setting );
$current_course_values   = mergeCourseSettings( $current_course_values, $updated_optional_setting );

is_deeply( $current_course_values, $updated_course_settings, "course_settings: updated optional setting" );

# set a single course setting in problem_set

my $updated_problem_set_setting = { problem_set => { time_assign_due => "11:52" } };
$updated_course_settings = $course_rs->updateCourseSettings( $new_course_info, $updated_problem_set_setting );
$current_course_values   = mergeCourseSettings( $current_course_values, $updated_problem_set_setting );

is_deeply( $current_course_values, $updated_course_settings, "course_settings: updated problem set setting" );

# set a single course setting in problem

my $updated_problem_setting = { problem => { display_mode => "images" } };
$updated_course_settings = $course_rs->updateCourseSettings( $new_course_info, $updated_problem_setting );
$current_course_values   = mergeCourseSettings( $current_course_values, $updated_problem_setting );

is_deeply( $current_course_values, $updated_course_settings, "course_settings: updated problem setting" );

# make sure that an nonexistant setting throws an exception

my $undefined_problem_setting = { general => { non_existent_setting => 1 } };

throws_ok {
	$course_rs->updateCourseSettings( $new_course_info, $undefined_problem_setting );
}
"DB::Exception::UndefinedCourseField", "course settings: undefined course_setting field";

# make sure that an invalid list option setting throws an exception

my $invalid_list_option = { general => { hardcopy_theme => 'default' } };

$course_rs->updateCourseSettings( $new_course_info, $invalid_list_option );

# make sure that an invalid integer setting throws an exception

# make sure that an invalid email list setting throws an exception

# load the default settings:

# my $course_defaults = checkSettings("$main::webwork_home/conf/course_defaults.yml");

## finally delete the new course that was made;

$course_rs->deleteCourse( { course_id => $new_course->{course_id} } );

done_testing();

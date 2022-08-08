#!/usr/bin/env perl

# This tests the basic database CRUD functions with course settings.

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
use YAML::XS qw/LoadFile/;

use DB::Schema;

use WeBWorK3::Utils::Settings qw/getDefaultCourseSettings getDefaultCourseValues
	validateSettingsConfFile validateSingleCourseSetting validateSettingConfig
	isInteger isTimeString isTimeDuration isDecimal mergeCourseSettings/;

use TestUtils qw/removeIDs loadSchema/;

# Load the database
my $config_file = "$main::ww3_dir/conf/webwork3-test.yml";
$config_file = "$main::ww3_dir/conf/webwork3-test.dist.yml" unless (-e $config_file);
my $config = LoadFile($config_file);
my $schema = DB::Schema->connect(
	$config->{database_dsn},
	$config->{database_user},
	$config->{database_password},
	{ quote_names => 1 }
);

# Test for various types

ok(isInteger(0),     'check type: integer');
ok(isInteger(100),   'check type: integer');
ok(isInteger(-30),   'check type: integer');
ok(!isInteger(0.5),  'check type: not an integer');
ok(!isInteger(-2.5), 'check type: not an integer');

ok(isTimeString('1:59'),  'check type: 24-hour time string');
ok(isTimeString('01:59'), 'check type: 24-hour time string');
ok(isTimeString('00:59'), 'check type: 24-hour time string');
ok(isTimeString('11:59'), 'check type: 24-hour time string');
ok(isTimeString('13:59'), 'check type: 24-hour time string');
ok(isTimeString('21:00'), 'check type: 24-hour time string');

ok(!isTimeString('24:59'), 'check type: not a 24-hour time string');
ok(!isTimeString('31:59'), 'check type: not a 24-hour time string');
ok(!isTimeString('23:69'), 'check type: not a 24-hour time string');

ok(isTimeDuration('2 days'),   'check type: time duration');
ok(isTimeDuration('10 sec'),   'check type: time duration');
ok(isTimeDuration('12 min'),   'check type: time duration');
ok(isTimeDuration('24 hrs'),   'check type: time duration');
ok(isTimeDuration('24 hours'), 'check type: time duration');
ok(isTimeDuration('1 week'),   'check type: time duration');
ok(isTimeDuration('1 WEEK'),   'check type: time duration');

ok(!isTimeDuration('-24 hrs'),  'check type: not a time duration');
ok(!isTimeDuration('4 apples'), 'check type: not a time duration');

ok(isDecimal(0.3),    'check type: decimal');
ok(isDecimal(3),      'check type: decimal');
ok(isDecimal(-0.3),   'check type: decimal');
ok(isDecimal('0.33'), 'check type: decimal');
ok(isDecimal("-.33"), 'check type: decimal');

ok(isDecimal('00.33'),  'check type: decimal');
ok(!isDecimal("0-.33"), 'check type: not a decimal');
ok(!isDecimal('abc'),   'check type: not a decimal');

# Check that the configuration file is valid.
is(validateSettingsConfFile(), 1, 'configuration file valid');

# TODO: Test to make sure that all of the checks for the course configurations work.

my $default_course_settings = getDefaultCourseSettings();

# Check that each of the given course_setting types are both valid and invalid.
my $valid_setting = {
	var      => 'my_setting',
	doc      => 'this is a setting',
	type     => 'integer',
	category => 'general',
	default  => 0
};
is(validateSettingConfig($valid_setting), 1, 'course setting: valid setting');

# Check various parts of the setting.

throws_ok {
	validateSettingConfig({
		var      => 'mySetting',
		doc      => 'this is a setting',
		type     => 'integer',
		category => 'general',
		default  => 0
	})
}
'DB::Exception::InvalidCourseField', 'course setting: variable not in kebob case';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc3     => 'this is a setting',
		type     => 'integer',
		category => 'general',
		default  => 0
	})
}
'DB::Exception::InvalidCourseField', 'course setting: course setting with illegal field';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		type     => 'integer',
		category => 'general',
		default  => 0
	})
}
'DB::Exception::InvalidCourseField', 'course setting: missing required field';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc      => 'this is a setting',
		type     => 'nonnegint',
		category => 'general',
		default  => 0
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: non valid course parameter type';

# Validate settings

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc      => 'this is a setting',
		type     => 'time',
		category => 'general',
		default  => '12:343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad time string';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc      => 'this is a setting',
		type     => 'integer',
		category => 'general',
		default  => '12.343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad integer format';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc      => 'this is a setting',
		type     => 'time_duration',
		category => 'general',
		default  => '-2 days'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad time duration format';

throws_ok {
	validateSettingConfig({
		var      => 'my_setting',
		doc      => 'this is a setting',
		type     => 'decimal',
		category => 'general',
		default  => '12:343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad decimal format';

my $course_rs = $schema->resultset('Course');

# Check that the default settings are working

# Make a new course with no settings and compare to the default settings
my $new_course = $course_rs->addCourse(params => { course_name => 'New Course' });

my $default_course_values = getDefaultCourseValues();
my $new_course_info       = { course_id => $new_course->{course_id} };
my $course_settings       = $course_rs->getCourseSettings(info => $new_course_info);

is_deeply($course_settings, $default_course_values, 'course settings: default course_settings');

# Set a single course setting in General
my $updated_general_setting = { general => { course_description => 'This is my new course description' } };
my $updated_course_settings = $course_rs->updateCourseSettings(
	info     => $new_course_info,
	settings => $updated_general_setting
);
my $current_course_values = mergeCourseSettings($default_course_values, $updated_general_setting);

is_deeply($current_course_values, $updated_course_settings, 'course_settings: updated general setting');

# Update another general setting
$updated_general_setting = { general => { hardcopy_theme => 'One Column' } };

$updated_course_settings = $course_rs->updateCourseSettings(
	info     => $new_course_info,
	settings => $updated_general_setting
);

$current_course_values = mergeCourseSettings($current_course_values, $updated_general_setting);

is_deeply($current_course_values, $updated_course_settings, 'course_settings: updated another general setting');

# Set a single course setting in Optional Modules.
my $updated_optional_setting = { optional => { enable_show_me_another => 1 } };
$updated_course_settings =
	$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_optional_setting);
$current_course_values = mergeCourseSettings($current_course_values, $updated_optional_setting);
is_deeply($current_course_values, $updated_course_settings, 'course_settings: updated optional setting');

# Set a single course setting in problem_set.
my $updated_problem_set_setting = { problem_set => { time_assign_due => '11:52' } };
$updated_course_settings =
	$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_problem_set_setting);
$current_course_values = mergeCourseSettings($current_course_values, $updated_problem_set_setting);
is_deeply($current_course_values, $updated_course_settings, 'course_settings: updated problem set setting');

# Set a single course setting in problem.
my $updated_problem_setting = { problem => { display_mode => 'images' } };
$updated_course_settings =
	$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_problem_setting);
$current_course_values = mergeCourseSettings($current_course_values, $updated_problem_setting);
is_deeply($current_course_values, $updated_course_settings, 'course_settings: updated problem setting');

# Make sure that an nonexistant setting throws an exception.
my $undefined_problem_setting = { general => { non_existent_setting => 1 } };
throws_ok {
	$course_rs->updateCourseSettings(info => $new_course_info, settings => $undefined_problem_setting);
}
'DB::Exception::UndefinedCourseField', 'course settings: undefined course_setting field';

# Make sure that an invalid list option setting throws an exception.
my $invalid_list_option = { general => { hardcopy_theme => 'default' } };
$course_rs->updateCourseSettings(info => $new_course_info, settings => $invalid_list_option);

# TODO: Make sure that an invalid integer setting throws an exception

# TODO: Make sure that an invalid email list setting throws an exception

# Finally delete the course that was made
$course_rs->deleteCourse(info => { course_id => $new_course->{course_id} });

done_testing();

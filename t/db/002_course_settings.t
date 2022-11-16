#!/usr/bin/env perl

# This tests the basic database CRUD functions with course settings.

use Test2::V0;

# This must occur after Test2::V0 is loaded as that package enables all warnings.
use Mojo::Base -signatures;

use Mojo::File qw/curfile/;

use lib curfile->dirname->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('lib')->to_string;

use DBSubtest qw/dbSubtest/;

use WeBWorK3::Utils::Settings qw/getDefaultCourseValues validateSettingsConfFile validateSettingConfig
	isInteger isTimeString isTimeDuration isDecimal mergeCourseSettings/;

# Test for various types
subtest 'check types' => sub {
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
	ok(isDecimal('-.33'), 'check type: decimal');

	ok(isDecimal('00.33'),  'check type: decimal');
	ok(!isDecimal('0-.33'), 'check type: not a decimal');
	ok(!isDecimal('abc'),   'check type: not a decimal');
};

# Check that the configuration file is valid.
is(validateSettingsConfFile, 1, 'configuration file valid');

# TODO: Test to make sure that all of the checks for the course configurations work.

subtest 'check setting validation' => sub {

	# Check that each of the given course_setting types are both valid and invalid.
	is(
		validateSettingConfig({
			var      => 'my_setting',
			doc      => 'this is a setting',
			type     => 'integer',
			category => 'general',
			default  => 0
		}),
		1,
		'course setting: valid setting'
	);

	# Check various parts of the setting.

	is(
		dies {
			validateSettingConfig({
				var      => 'mySetting',
				doc      => 'this is a setting',
				type     => 'integer',
				category => 'general',
				default  => 0
			})
		},
		check_isa('DB::Exception::InvalidCourseField'),
		'course setting: variable not in kebob case'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc3     => 'this is a setting',
				type     => 'integer',
				category => 'general',
				default  => 0
			})
		},
		check_isa('DB::Exception::InvalidCourseField'),
		'course setting: course setting with illegal field'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				type     => 'integer',
				category => 'general',
				default  => 0
			})
		},
		check_isa('DB::Exception::InvalidCourseField'),
		'course setting: missing required field'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc      => 'this is a setting',
				type     => 'nonnegint',
				category => 'general',
				default  => 0
			})
		},
		check_isa('DB::Exception::InvalidCourseFieldType'),
		'course setting: non valid course parameter type'
	);

	# Validate settings

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc      => 'this is a setting',
				type     => 'time',
				category => 'general',
				default  => '12:343'
			})
		},
		check_isa('DB::Exception::InvalidCourseFieldType'),
		'course setting: bad time string'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc      => 'this is a setting',
				type     => 'integer',
				category => 'general',
				default  => '12.343'
			})
		},
		check_isa('DB::Exception::InvalidCourseFieldType'),
		'course setting: bad integer format'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc      => 'this is a setting',
				type     => 'time_duration',
				category => 'general',
				default  => '-2 days'
			})
		},
		check_isa('DB::Exception::InvalidCourseFieldType'),
		'course setting: bad time duration format'
	);

	is(
		dies {
			validateSettingConfig({
				var      => 'my_setting',
				doc      => 'this is a setting',
				type     => 'decimal',
				category => 'general',
				default  => '12:343'
			})
		},
		check_isa('DB::Exception::InvalidCourseFieldType'),
		'course setting: bad decimal format'
	);
};

dbSubtest 'course settings' => sub ($schema) {
	my $course_rs = $schema->resultset('Course');

	# Check that the default settings are working

	# Make a new course with no settings and compare to the default settings
	my $new_course = $course_rs->addCourse(params => { course_name => 'New Course' });

	my $default_course_values = getDefaultCourseValues();
	my $new_course_info       = { course_id => $new_course->{course_id} };
	my $course_settings       = $course_rs->getCourseSettings(info => $new_course_info);

	is($course_settings, $default_course_values, 'course settings: default course_settings');

	# Set a single course setting in General
	my $updated_general_setting = { general => { course_description => 'This is my new course description' } };
	my $updated_course_settings = $course_rs->updateCourseSettings(
		info     => $new_course_info,
		settings => $updated_general_setting
	);
	my $current_course_values = mergeCourseSettings($default_course_values, $updated_general_setting);

	is($current_course_values, $updated_course_settings, 'course_settings: updated general setting');

	# Update another general setting
	$updated_general_setting = { general => { hardcopy_theme => 'One Column' } };

	$updated_course_settings = $course_rs->updateCourseSettings(
		info     => $new_course_info,
		settings => $updated_general_setting
	);

	$current_course_values = mergeCourseSettings($current_course_values, $updated_general_setting);

	is($current_course_values, $updated_course_settings, 'course_settings: updated another general setting');

	# Set a single course setting in Optional Modules.
	my $updated_optional_setting = { optional => { enable_show_me_another => 1 } };
	$updated_course_settings =
		$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_optional_setting);
	$current_course_values = mergeCourseSettings($current_course_values, $updated_optional_setting);
	is($current_course_values, $updated_course_settings, 'course_settings: updated optional setting');

	# Set a single course setting in problem_set.
	my $updated_problem_set_setting = { problem_set => { time_assign_due => '11:52' } };
	$updated_course_settings =
		$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_problem_set_setting);
	$current_course_values = mergeCourseSettings($current_course_values, $updated_problem_set_setting);
	is($current_course_values, $updated_course_settings, 'course_settings: updated problem set setting');

	# Set a single course setting in problem.
	my $updated_problem_setting = { problem => { display_mode => 'images' } };
	$updated_course_settings =
		$course_rs->updateCourseSettings(info => $new_course_info, settings => $updated_problem_setting);
	$current_course_values = mergeCourseSettings($current_course_values, $updated_problem_setting);
	is($current_course_values, $updated_course_settings, 'course_settings: updated problem setting');

	# Make sure that an nonexistant setting throws an exception.
	my $undefined_problem_setting = { general => { non_existent_setting => 1 } };
	is(
		dies {
			$course_rs->updateCourseSettings(
				info     => $new_course_info,
				settings => $undefined_problem_setting
			);
		},
		check_isa('DB::Exception::UndefinedCourseField'),
		'course settings: undefined course_setting field'
	);

	# Make sure that an invalid list option setting throws an exception.
	my $invalid_list_option = { general => { hardcopy_theme => 'default' } };
	$course_rs->updateCourseSettings(info => $new_course_info, settings => $invalid_list_option);

	# TODO: Make sure that an invalid integer setting throws an exception

	# TODO: Make sure that an invalid email list setting throws an exception
};

done_testing();

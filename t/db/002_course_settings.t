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
use Mojo::JSON qw/true false/;
use YAML::XS qw/LoadFile/;

use DB::Schema;

use WeBWorK3::Utils::Settings qw/isInteger isTimeString isTimeDuration isDecimal mergeCourseSettings
	isValidSetting/;

use DB::Utils qw/convertTimeDuration/;
use TestUtils qw/removeIDs loadCSV/;

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

# Check that time duration conversion works as intended.
is(convertTimeDuration('15 sec'), 15, 'convertTimeDuration: 15 sec');
is(convertTimeDuration('15 secs'), 15, 'convertTimeDuration: 15 secs');

is(convertTimeDuration('15 min'), 900, 'convertTimeDuration: 15 min');
is(convertTimeDuration('15 mins'), 900, 'convertTimeDuration: 15 mins');
is(convertTimeDuration('15 minute'), 900, 'convertTimeDuration: 15 minute');
is(convertTimeDuration('15 minutes'), 900, 'convertTimeDuration: 15 minutes');

is(convertTimeDuration('6 hour'), 21600, 'convertTimeDuration: 6 hour');
is(convertTimeDuration('6 hours'), 21600, 'convertTimeDuration: 6 hours');
is(convertTimeDuration('6 hr'), 21600, 'convertTimeDuration: 6 hr');
is(convertTimeDuration('6 hrs'), 21600, 'convertTimeDuration: 6 hrs');

is(convertTimeDuration('3 day'), 259200, 'convertTimeDuration: 3 day');
is(convertTimeDuration('3 days'), 259200, 'convertTimeDuration: 3 days');

is(convertTimeDuration('2 week'), 1209600, 'convertTimeDuration: 2 week');
is(convertTimeDuration('2 weeks'), 1209600, 'convertTimeDuration: 2 weeks');

# Check that each of the given course_setting types are both valid and invalid.
my $valid_setting = {
	setting_name  => 'my_setting',
	description   => 'this is a setting',
	type          => 'int',
	category      => 'general',
	default_value => 0
};
ok(isValidSetting($valid_setting), 'course setting: valid setting');

# Check that the setting hash has only valid fields
throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		doc3          => 'this is a setting',
		type          => 'int',
		category      => 'general',
		default_value => 0
	})
}
'DB::Exception::InvalidCourseField', 'course setting: course setting with illegal field';

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		type          => 'int',
		category      => 'general',
		default_value => 0
	})
}
'DB::Exception::InvalidCourseField', 'course setting: missing required field';

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		description   => 'this is a setting',
		type          => 'nonnegint',
		category      => 'general',
		default_value => 0
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: non valid course parameter type';

# Validate settings

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		description   => 'this is a setting',
		type          => 'time',
		category      => 'general',
		default_value => '12:343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad time string';

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		description   => 'this is a setting',
		type          => 'integer',
		category      => 'general',
		default_value => '12.343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad integer format';

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		description   => 'this is a setting',
		type          => 'time_duration',
		category      => 'general',
		default_value => '-2 days'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad time duration format';

throws_ok {
	isValidSetting({
		setting_name  => 'my_setting',
		description   => 'this is a setting',
		type          => 'decimal',
		category      => 'general',
		default_value => '12:343'
	})
}
'DB::Exception::InvalidCourseFieldType', 'course setting: bad decimal format';

my $course_rs = $schema->resultset('Course');

# Check that the default_value  settings are the same as the values in the file

my $global_settings = $course_rs->getGlobalSettings();
for my $setting (@$global_settings) {
	removeIDs($setting);
	for my $key (qw/doc subcategory options/) {
		delete $setting->{$key} unless $setting->{$key};
	}
}

# Ensure that booleans in the YAML file are loaded correctly.
local $YAML::XS::Boolean = "JSON::PP";
my $settings_file = "$main::ww3_dir/conf/course_settings.yml";
$settings_file = "$main::ww3_dir/conf/course_settings.dist.yml" unless -r $settings_file;
my $global_settings_from_file = LoadFile($settings_file);

# sort each of these for comparison
my @global_settings           = sort { $a->{setting_name} cmp $b->{setting_name} } @$global_settings;
my @global_settings_from_file = sort { $a->{setting_name} cmp $b->{setting_name} } @$global_settings_from_file;

is_deeply(\@global_settings, \@global_settings_from_file,
	'default settings: db values are the same as the file values.');

# Make sure all of the default settings are valid
for my $setting (@$global_settings) {
	ok(isValidSetting($setting), "check default setting: $setting->{setting_name} is valid");
}

# Make a new course with no settings and compare to the default settings
my $new_course = $course_rs->addCourse(params => { course_name => 'New Course' });

my $course_settings = $course_rs->getCourseSettings(info => { course_id => $new_course->{course_id} });

# check that the course_settings is an array of length 0.
is_deeply($course_settings, [], 'course settings from a new course is just the defaults.');

# Compare the course settings with the file.

# Get a list of courses from the CSV file.
my @course_settings_from_csv = loadCSV("$main::ww3_dir/t/db/sample_data/course_settings.csv");
my @arith_settings           = grep { $_->{course_name} eq 'Arithmetic' } @course_settings_from_csv;
@arith_settings = map { { setting_name => $_->{setting_name}, value => $_->{setting_value} }; } @arith_settings;

my $arith_settings_from_db = $course_rs->getCourseSettings(info => { course_name => 'Arithmetic' }, merged => 1);
for my $setting (@$arith_settings_from_db) {
	removeIDs($setting);
}

# Only compare the name/value of the settings
for my $setting (@$arith_settings_from_db) {
	$setting = { setting_name => $setting->{setting_name}, value => $setting->{value} };
}
is_deeply($arith_settings_from_db, \@arith_settings, 'getCourseSettings: compare settings for given course');

my $updated_setting = $course_rs->updateCourseSetting(
	info => {
		course_id    => $new_course->{course_id},
		setting_name => 'course_description'
	},
	params => { value => 'This is my new course description' }
);

# Check that updating a boolean is a JSON boolean

my $boolean_setting = $course_rs->updateCourseSetting(
	info => {
		course_id    => $new_course->{course_id},
		setting_name => 'enable_conditional_release'
	},
	params => { value => true }
);

is($boolean_setting->{value}, true, 'updateCourseSetting: ensure that a value is truthy');
ok(JSON::PP::is_bool($boolean_setting->{value}), 'updateCourseSetting: ensure that a value is a JSON boolean');

is(
	'This is my new course description',
	$updated_setting->{value},
	'updateCourseSetting: successfully update a course setting'
);

my $fetched_setting = $course_rs->getCourseSetting(
	info => {
		course_id    => $new_course->{course_id},
		setting_name => 'course_description'
	}
);

is($fetched_setting->{value}, $updated_setting->{value}, 'getCourseSetting: fetch a single course setting');

# Make sure invalid course settings throw exceptions.

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'non_existant_setting'
		},
		params => { value => 3 }
	);
}
'DB::Exception::SettingNotFound', 'updateCourseSetting: try to update a non-existant course setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'language'
		},
		params => { value => 'Klingon' }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update the list setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'session_key_timeout'
		},
		params => { value => '45 years' }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update a time_duration setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'enable_reduced_scoring'
		},
		params => { value => 'true' }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update a boolean setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'show_me_another_default'
		},
		params => { value => 'true' }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update an integer setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'display_mode_options'
		},
		params => { value => [ '1', '2' ] }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update a multilist setting.';

throws_ok {
	$course_rs->updateCourseSetting(
		info => {
			course_id    => $new_course->{course_id},
			setting_name => 'num_rel_percent_tol_default'
		},
		params => { value => 'true' }
	);
}
'DB::Exception::InvalidCourseFieldType', 'updateCourseSetting: try to update a decimal setting.';

# Delete a course setting

my $deleted_setting = $course_rs->deleteCourseSetting(
	info => {
		course_name  => 'New Course',
		setting_name => 'course_description'
	}
);

is_deeply($deleted_setting, $updated_setting, 'deleteCourseSetting: delete a course setting.');

my $deleted_setting2 = $course_rs->deleteCourseSetting(
	info => {
		course_name  => 'New Course',
		setting_name => 'enable_conditional_release'
	}
);

is_deeply($deleted_setting2, $boolean_setting, 'deleteCourseSetting: delete another course setting.');

# Finally delete the course that was made
$course_rs->deleteCourse(info => { course_id => $new_course->{course_id} });

done_testing();

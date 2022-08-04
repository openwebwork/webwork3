package WeBWorK3::Utils::Settings;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use YAML::XS qw/LoadFile/;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/checkSettings getDefaultCourseSettings getDefaultCourseValues
	mergeCourseSettings validateSettingsConfFile validateCourseSettings
	validateSingleCourseSetting validateSettingConfig
	isInteger isTimeString isTimeDuration isDecimal/;

use Exception::Class qw(
	DB::Exception::UndefinedCourseField
	DB::Exception::InvalidCourseField
	DB::Exception::InvalidCourseFieldType
);

use WeBWorK3;

my @allowed_fields  = qw/var category subcategory doc doc2 default type options/;
my @required_fields = qw/var doc type default/;

=head1 loadDefaultCourseSettings

load the default settings from the conf/course_settings.yaml file

=cut

sub getDefaultCourseSettings () {
	return LoadFile(Mojo::Home->new->detect->child('conf', 'course_defaults.yml'));
}

my @course_setting_categories = qw/email optional general permissions problem problem_set/;

=head1 getDefaultCourseValues

getDefaultCourseValues returns the values of all default course values and returns
it as a hash of categories/variables

=cut

sub getDefaultCourseValues () {
	my $course_defaults = getDefaultCourseSettings();    # The full default course settings

	my $all_settings = {};
	for my $category (@course_setting_categories) {
		$all_settings->{$category} = {};
		my @settings = grep { $_->{category} eq $category } @$course_defaults;
		for my $setting (@settings) {
			$all_settings->{$category}->{ $setting->{var} } = $setting->{default};
		}
	}
	return $all_settings;
}

=head1 mergeCourseSettings

mergeCourseSettings takes in two settings and merges them in the following way:

For each course setting in the first argument (typically from the configuration file)
1. If a value in the second argument is present use that else
2. use the value from the first argument

=cut

sub mergeCourseSettings ($settings, $settings_to_update) {
	my $updated_settings = {};

	# Merge the non-optional categories.
	for my $category (@course_setting_categories) {
		$updated_settings->{$category} = {};
		my @fields = keys %{ $settings->{$category} };
		push(@fields, keys %{ $settings_to_update->{$category} });
		for my $key (@fields) {
			# Use the value in $settings_to_update if it exists, if not use the other.
			$updated_settings->{$category}->{$key} =
				$settings_to_update->{$category}->{$key} || $settings->{$category}->{$key};
		}
	}

	return $updated_settings;
}

=pod

checkSettingsConfFile loads the course settings configuration file and checks for validity

=cut

sub validateSettingsConfFile () {
	#my @all_settings = getDefaultCourseSettings();
	for my $setting (@{ getDefaultCourseSettings() }) {
		validateSettingConfig($setting);
	}
	return 1;
}

=pod

isValidCourseSettings checks if the course settings are valid including

=over

=item the key is defined in the course setting configuration file

=item the value is appropriate for the given setting.

=back

=cut

sub flattenCourseSettings ($settings) {
	my @flattened_settings = ();
	for my $category (keys %$settings) {
		for my $var (keys %{ $settings->{$category} }) {
			push(
				@flattened_settings,
				{
					var      => $var,
					category => $category,
					value    => $settings->{$category}->{$var}
				}
			);
		}
	}
	return \@flattened_settings;
}

sub validateCourseSettings ($course_settings) {
	$course_settings = flattenCourseSettings($course_settings);
	my $default_course_settings = getDefaultCourseSettings();
	for my $setting (@$course_settings) {
		validateSingleCourseSetting($setting, $default_course_settings);
	}
	return 1;
}

sub validateSingleCourseSetting ($setting, $default_course_settings) {
	my @default_setting = grep { $_->{var} eq $setting->{var} } @$default_course_settings;
	DB::Exception::UndefinedCourseField->throw(message => qq/The course setting $setting->{var} is not valid/)
		unless scalar(@default_setting) == 1;

	validateSetting($setting);

	return 1;
}

=pod

This checks the variable name (to ensure it is in kebob case)

=cut

sub kebobCase ($in) {
	return $in =~ /^[a-z][a-z_\d]*[a-z\d]$/;
}

=head1 validateSettingsConfig

This checks the configuration for a single setting is valid.  This includes

=over

=item Check that the variable name is kebob case

=item Ensure that all fields passed in are valid

=item Ensure that all require fields are present

=item Checks that the default value is appropriate for the type

=back

=cut

my @valid_types = qw/text list multilist boolean integer decimal time date_time time_duration timezone/;

sub validateSettingConfig ($setting) {
	# Check that the variable name is kebobCase.
	DB::Exception::InvalidCourseField->throw(message => "The variable name $setting->{var} must be in kebob case")
		unless kebobCase($setting->{var});

	# Check that each of the setting fields is allowed.
	for my $field (keys %$setting) {
		my @fields = grep { $_ eq $field } @allowed_fields;
		DB::Exception::InvalidCourseField->throw(
			message => "The field: $field is not an allowed field of the setting $setting->{var}")
			if scalar(@fields) == 0;
	}

	# Check that each of the required fields is present in the setting.
	for my $field (@required_fields) {
		my @fields = grep { $_ eq $field } (keys %$setting);
		DB::Exception::InvalidCourseField->throw(
			message => "The field: $field is a required field for the setting $setting->{var}")
			if scalar(@fields) == 0;
	}

	my @type = grep { $_ eq $setting->{type} } @valid_types;
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The setting type: $setting->{type} is not valid for variable: $setting->{var}")
		unless scalar(@type) == 1;

	return validateSetting($setting);
}

sub validateSetting ($setting) {
	my $value = $setting->{default} || $setting->{value};

	return 0 if !defined $setting->{type};

	if ($setting->{type} eq 'list') {
		validateList($setting);
	} elsif ($setting->{type} eq 'time') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The default for variable $setting->{var} which is $value must be a time value/)
			unless isTimeString($setting->{default});
	} elsif ($setting->{type} eq 'integer') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The default for variable $setting->{var} which is $value must be an integer/)
			unless isInteger($setting->{default});
	} elsif ($setting->{type} eq 'decimal') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The default for variable $setting->{var} which is $value must be a decimal/)
			unless isDecimal($setting->{default});
	} elsif ($setting->{type} eq 'time_duration') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The default for variable $setting->{var} which is $value must be a time duration/)
			unless isTimeDuration($setting->{default});
	}
	return 1;
}

sub validateList ($setting) {
	DB::Exception::InvalidCourseFieldType->throw(
		message => qq/The options field for the type list in $setting->{var} is missing/)
		unless defined($setting->{options});

	DB::Exception::InvalidCourseFieldType->throw(
		message => qq/The options field for $setting->{var} is not an ARRAYREF/)
		unless ref($setting->{options}) eq 'ARRAY';

	# See if the $setting->{options} is an arrayref of strings or hashrefs.
	my @opt =
		(ref($setting->{options}->[0]) eq 'HASH')
		? grep { $_ eq $setting->{default} } map { $_->{value} } @{ $setting->{options} }
		: grep { $_ eq $setting->{default} } @{ $setting->{options} };

	DB::Exception::InvalidCourseFieldType->throw(
		message => qq/The default for variable $setting->{var} needs to be one of the given options/)
		unless scalar(@opt) == 1;

	return 1;
}

sub isInteger ($in) {
	return $in =~ /^-?\d+$/;
}

# Test for a 24-hour time string
sub isTimeString ($in) {
	return $in =~ /(^0?\d:[0-5]\d$)|(^1\d:[0-5]\d$)|(^2[0-3]:[0-5]\d$)/;
}

# Test for a time duration which can have the unit: sec, min, day, week, hr, hour
sub isTimeDuration ($in) {
	return $in =~ /^(\d+)\s(sec|second|min|minute|day|week|hr|hour)s?$/i;
}

sub isDecimal ($in) {
	return $in =~ /(^-?\d+(\.\d+)?$)|(^-?\.\d+$)/;
}

1;

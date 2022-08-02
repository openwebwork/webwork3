package WeBWorK3::Utils::Settings;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use YAML::XS qw/LoadFile/;
use Mojo::Home;
use Carp;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw/isValidSetting mergeCourseSettings isInteger isTimeString isTimeDuration isDecimal/;

use Exception::Class qw(
	DB::Exception::UndefinedCourseField
	DB::Exception::InvalidCourseField
	DB::Exception::InvalidCourseFieldType
);

use DateTime::TimeZone;
use JSON::PP;
use Array::Utils qw/array_minus/;

my @allowed_fields            = qw/setting_name category subcategory description doc default_value type options/;
my @required_fields           = qw/setting_name description type default_value/;
my @course_setting_categories = qw/email optional general permissions problem problem_set/;
my @valid_types               = qw/text list multilist boolean int decimal time date_time time_duration timezone/;

=head1 loadDefaultCourseSettings

load the default settings from the conf/course_settings.yaml file

=cut

sub getDefaultCourseSettings () {
	return LoadFile(Mojo::Home->new->detect->child('conf', 'course_defaults.yml'));
}


=pod

=head2 isValidSetting

This checks if the setting given the type, value and list of options (if needed). This includes

=over

=item Ensure that all fields passed in are valid

=item Ensure that all require fields are present

=item Checks that the default value is appropriate for the type

=back

=cut

sub isValidSetting ($setting, $value = undef) {
	return 0 if !defined $setting->{type};

	# If $value is not passed in, use the default_value for the setting
	my $val = $value // $setting->{default_value};
	# Check that each of the setting fields is allowed.
	for my $field (keys %$setting) {
		my @fields = grep { $_ eq $field } @allowed_fields;
		DB::Exception::InvalidCourseField->throw(
			message => "The field: $field is not an allowed field of the setting $setting->{setting_name}")
			if scalar(@fields) == 0;
	}

	# Check that each of the required fields is present in the setting.
	for my $field (@required_fields) {
		my @fields = grep { $_ eq $field } (keys %$setting);
		DB::Exception::InvalidCourseField->throw(
			message => "The field: $field is a required field for the setting $setting->{setting_name}")
			if scalar(@fields) == 0;
	}

	if ($setting->{type} eq 'text') {
		# any val is valid.
	} elsif ($setting->{type} eq 'boolean') {
		my $is_bool = JSON::PP::is_bool($val);
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The variable $setting->{setting_name} has value $val and must be a boolean./)
			unless $is_bool;
	} elsif ($setting->{type} eq 'list') {
		validateList($setting, $val);
	} elsif ($setting->{type} eq 'multilist') {
		validateMultilist($setting, $val);
	} elsif ($setting->{type} eq 'time') {
		DB::Exception::InvalidCourseFieldType->throw(message =>
				qq/The variable $setting->{setting_name} has value $val and must be a time in the form XX:XX/)
			unless isTimeString($val);
	} elsif ($setting->{type} eq 'int') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The variable $setting->{setting_name} has value $val and must be an integer./)
			unless isInteger($val);
	} elsif ($setting->{type} eq 'decimal') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The variable $setting->{setting_name} has value $val and must be a decimal/)
			unless isDecimal($val);
	} elsif ($setting->{type} eq 'time_duration') {
		DB::Exception::InvalidCourseFieldType->throw(
			message => qq/The variable $setting->{setting_name} has value $val and must be a time duration/)
			unless isTimeDuration($val);
	} elsif ($setting->{type} eq 'timezone') {
		# try to make a new timeZone.  If the name isn't valid an 'Invalid offset:' will be thrown.
		DateTime::TimeZone->new(name => $val);
	} else {
		DB::Exception::InvalidCourseFieldType->throw(message => qq/The setting type $setting->{type} is not valid/);
	}
	return 1;
}

=pod

=head2 validateList

This returns true if a valid setting of type 'list' given its value.  Specifically, the options
field of the setting must exist and the value must be an elemeent in the array.

Note: the options arrayref may contain hashes of label/value pairs, which is used
on the UI.

=cut

sub validateList ($setting, $value) {
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The options field for the type list in $setting->{setting_name} is missing ")
		unless defined($setting->{options});
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The options field for $setting->{setting_name} is not an ARRAYREF")
		unless ref($setting->{options}) eq 'ARRAY';

	# See if the $setting->{options} is an arrayref of strings or hashrefs.
	my @opt =
		(ref($setting->{options}->[0]) eq 'HASH')
		? grep { $_ eq $value } map { $_->{value} } @{ $setting->{options} }
		: grep { $_ eq $value } @{ $setting->{options} };
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The default for variable $setting->{setting_name} needs to be one of the given options")
		unless scalar(@opt) == 1;

	return 1;
}

=pod
=head2 validateMultilist

This returns true if the setting of type mutlilist is valid.  If not, a error is thrown.
A valid mutilist is one in which the value is a subset of the options.  Unlike a list, a
multilist is only arrayrefs of strings (not label/value pairs).

=cut

sub validateMultilist ($setting, $value) {
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The options field for the type multilist in $setting->{setting_name} is missing ")
		unless defined($setting->{options});
	DB::Exception::InvalidCourseFieldType->throw(
		message => "The options field for $setting->{setting_name} is not an ARRAYREF")
		unless ref($setting->{options}) eq 'ARRAY';

	my @diff = array_minus(@{ $setting->{options} }, @$value);
	throw DB::Exception::InvalidCourseFieldType->throw(
		message => "The values for $setting->{setting_name} must be a subset of the options field")
		unless scalar(@diff) == 0;
}

# Test for an integer.
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

# Test for a decimal.
sub isDecimal ($in) {
	return $in =~ /(^-?\d+(\.\d+)?$)|(^-?\.\d+$)/;
}

1;

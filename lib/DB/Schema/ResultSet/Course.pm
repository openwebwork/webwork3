package DB::Schema::ResultSet::Course;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base 'DBIx::Class::ResultSet';

use Clone qw/clone/;
use DB::Utils qw/getCourseInfo getUserInfo getSettingInfo/;

use Exception::Class qw(
	DB::Exception::CourseNotFound
	DB::Exception::CourseExists
	DB::Exception::SettingNotFound
);

use WeBWorK3::Utils::Settings qw/ mergeCourseSettings isValidSetting/;

=head1 DESCRIPTION

This is the functionality of a Course in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for anything on the
global courses level.

Unless otherwise indicated, all of the methods here return either one of two types:

=over

=item *

A Course described by a C<DBIx::Class:ResultSet::Course> object if C<$as_result_set> is true.

=item *

A Course as a hashref with the fields described in L<DBIx::Class:Result::Course>.

=back

=cut

=head2 getCourses

This gets a list of Courses stored in the database in the C<courses> table.

=head3 input

C<$as_result_set>, a boolean if the return is to be a result_set

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getCourses ($self, %args) {
	my @courses = $self->search();
	return @courses if $args{as_result_set};
	return map {
		{ $_->get_inflated_columns };
	} @courses;
}

=head2 getCourse

This gets a single course that is stored in the database in the C<courses> table.

=head3 input

=over

=item *

C<info>, a hashref containing either C<course_name> or C<course_id>

=item *

C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

The course either as a C< DBIx::Class::ResultSet::Course> object or a hashref
of the fields. See above.

=cut

sub getCourse ($self, %args) {
	my $course = $self->find(getCourseInfo($args{info}));
	unless (defined($course)) {
		my $info = getCourseInfo($args{info});
		DB::Exception::CourseNotFound->throw(message => "The course: $info->{course_name} does not exist.")
			if defined($info->{course_name});
		DB::Exception::CourseNotFound->throw(
			message => "The course with course_id of $info->{course_id} does not exist.")
			if defined($info->{course_id});
	}

	return $course if $args{as_result_set};

	return { $course->get_inflated_columns };
}

=head2 addCourse

Adds a single course to the database in the C<courses> table.

=over

=item *

C<params>, a hashref containing either C<course_name> or C<course_id>

=item *

C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

The course either as a C< DBIx::Class::ResultSet::Course> object or a hashref
of the fields. See above.

=cut

sub addCourse ($self, %args) {
	my $course_params = clone $args{params};
	DB::Exception::ParametersNeeded->throw(message => 'The parameters must include course_name')
		unless defined($course_params->{course_name});

	# Check if the course exists.  If so throw an error.
	my $course = $self->find({ course_name => $course_params->{course_name} });

	DB::Exception::CourseAlreadyExists->throw(course_name => $course_params->{course_name}) if defined($course);

	my $params = {};
	for my $field (qw/course_name visible course_dates/) {
		# This should be looked up.
		$params->{$field} = $course_params->{$field} if defined($course_params->{$field});
	}

	# Check the parameters.
	my $new_course = $self->create($params);

	return $new_course if $args{as_result_set};
	return { $new_course->get_inflated_columns };
}

=head2 deleteCourse

This deletes a single course that is stored in the database in the C<courses> table.

=head3 input

=over

=item *

C<course_info>, a hashref containing either C<course_name> or C<course_id>

=item *

C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

The deleted course either as a C< DBIx::Class::ResultSet::Course> object or a hashref
of the fields. See above.

=cut

sub deleteCourse ($self, %args) {
	my $course_to_delete = $self->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);

	my $deleted_course = $course_to_delete->delete;
	return $deleted_course if $args{as_result_set};

	return { $course_to_delete->get_inflated_columns };
}

=head1 updateCourse

This updates a single course that is stored in the database in the C<courses> table.

=head3 input

=over

=item * C<info>, either C<course_name> or C<course_id>

=item * C<params>: A hash of the course parameters to be updated.

=back

=head3 output

The updated course as a C<DBIx::Class::ResultSet::Course> object or a hashref.

=cut

sub updateCourse ($self, %args) {
	my $course = $self->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
	## TODO: check the validity of the params
	my $course_to_return = $course->update($args{params});

	return $course_to_return if $args{as_result_set};
	return { $course_to_return->get_inflated_columns };
}

=head2 getUserCourses

This gets a list of Courses for a given user

=head3 input

=over

=item * hashref containing info about the user

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getUserCourses ($self, %args) {
	my $user = $self->result_source->schema->resultset('User')
		->getGlobalUser(info => getUserInfo($args{info}), as_result_set => 1);

	# my @user_courses = $user->courses->search({});

	my @user_courses = $user->course_users->search({}, { prefetch => [qw/role/] });

	return @user_courses if $args{as_result_set};
	my @user_courses_hashref = ();
	for my $user_course (@user_courses) {

		my $params = {
			$user_course->get_inflated_columns, $user_course->courses->get_inflated_columns,
			role => $user_course->role->role_name
		};
		push(@user_courses_hashref, $params);
	}
	return @user_courses_hashref;
}

=pod

=head2 getGlobalSettings

This gets the Global/Default Settings for all courses

=head3 input

=over

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getGlobalSettings ($self, %args) {
	my @global_settings = $self->result_source->schema->resultset('GlobalSetting')->search({});

	return \@global_settings if $args{as_result_set};
	my @settings = map {
		{ $_->get_inflated_columns };
	} @global_settings;
	for my $setting (@settings) {
		# The default_value is stored as a JSON and needs to be parsed.
		$setting->{default_value} = $setting->{default_value}->{value};
	}
	return \@settings;
}

=pod

=head2 getGlobalSetting

This gets a single global/default setting.

=head3 input

=over

=item * C<info> which is a hash of either a C<setting_id> or C<setting_name> with information
on the setting.

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

A single global/default setting.

=cut

sub getGlobalSetting ($self, %args) {
	my $setting_info   = getSettingInfo($args{info});
	my $global_setting = $self->result_source->schema->resultset('GlobalSetting')->find($setting_info);

	DB::Exception::SettingNotFound->throw(message => $setting_info->{setting_name}
		? "The setting with name $setting_info->{setting_name} is not found"
		: "The setting with setting_id $setting_info->{setting_id} is not found")
		unless $global_setting;
	return $global_setting if $args{as_result_set};
	my $setting_to_return = { $global_setting->get_inflated_columns };
	$setting_to_return->{default_value} = $setting_to_return->{default_value}->{value};
	return $setting_to_return;
}

=head2 getCourseSettings

This gets the Course Settings for a course

=head3 input

=over

=item * C<info>, hashref containing info about the course

=item * C<merged>, a boolean on whether the course setting is merged with its corresponding
global setting.

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of course settings as a C<DBIx::Class::ResultSet::CourseSetting> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getCourseSettings ($self, %args) {
	my $course           = $self->getCourse(info => $args{info}, as_result_set => 1);
	my @settings_from_db = $course->course_settings;

	return \@settings_from_db if $args{as_result_set};
	my @settings_to_return;
	if ($args{merged}) {
		@settings_to_return = map {
			{ $_->get_inflated_columns, $_->global_setting->get_inflated_columns };
		} @settings_from_db;
		for my $setting (@settings_to_return) {
			$setting->{default_value} = $setting->{default_value}->{value};
		}
	} else {
		@settings_to_return = map {
			{ $_->get_inflated_columns };
		} @settings_from_db;
	}
	return \@settings_to_return;
}

=pod

=head2 getCourseSetting

This gets a single course setting.

=head3 input

=over

=item * C<info> which is a hash of either a C<setting_id> or C<setting_name> with information
on the setting.

=item * C<merged>, a boolean on whether the course setting is merged with its corresponding
global setting.

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

A single course setting as either a hashref or a C<DBIx::Class::ResultSet::CourseSetting> object.

=cut

sub getCourseSetting ($self, %args) {

	my $global_setting = $self->getGlobalSetting(info => $args{info}, as_result_set => 1);
	DB::Exception::SettingNotFound->throw(
		message => "The setting with name: '" . $args{info}->{setting_name} . "' is not a defined info.")
		unless defined($global_setting);

	my $course  = $self->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);
	my $setting = $course->course_settings->find({ setting_id => $global_setting->setting_id });

	return $setting if $args{as_result_set};
	if ($args{merged}) {
		my $setting_to_return = { $setting->get_inflated_columns, $setting->global_setting->get_inflated_columns };
		$setting_to_return->{default_value} = $setting_to_return->{default_value}->{value};
		return $setting_to_return;
	} else {
		return { $setting->get_inflated_columns };
	}
}

=pod

=head2 updateCourseSetting

Update a single course setting.

=head3 input

=over

=item * C<info> which is a hash containing information about the course (either a
C<course_id> or C<course_name>) and a setting (either a C<setting_id> or C<setting_name>).

=item * C<params> the updated value of the course setting.

=item * C<merged>, a boolean on whether the course setting is merged with its corresponding
global setting.

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

A single course setting as either a hashref or a C<DBIx::Class::ResultSet::CourseSetting> object.

=cut
use Data::Dumper;
sub updateCourseSetting ($self, %args) {
	my $course = $self->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);

	my $global_setting = $self->getGlobalSetting(info => getSettingInfo($args{info}));

	my $course_setting = $course->course_settings->find({
		setting_id => $global_setting->{setting_id}
	});

	# Check that the setting is valid.

	my $params = {
		course_id  => $course->course_id,
		setting_id => $global_setting->{setting_id},
		value      => $args{params}->{value}
	};

	# remove the following fields before checking for valid settings:
	for (qw/setting_id course_id/) { delete $global_setting->{$_}; }

	isValidSetting($global_setting, $params->{value});

	# The course_id must be deleted to ensure it is written to the database correctly.
	delete $params->{course_id} if defined($params->{course_id});

	my $updated_course_setting = defined($course_setting) ? $course_setting->update($params) : $course->add_to_course_settings($params);

	if ($args{merged}) {
		my $setting_to_return = {
			$updated_course_setting->get_inflated_columns,
			$updated_course_setting->global_setting->get_inflated_columns
		};
		$setting_to_return->{default_value} = $setting_to_return->{default_value}->{value};
		return $setting_to_return;
	} else {
		return { $updated_course_setting->get_inflated_columns };
	}


	return $args{as_result_set} ? $updated_course_setting : { $updated_course_setting->get_inflated_columns };
}

=pod

=head2 deleteCourseSetting

Delete a single course setting.

=head3 input

=over

=item * C<info> which is a hash containing information about the course (either a
C<course_id> or C<course_name>) and a setting (either a C<setting_id> or C<setting_name>).

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

A single course setting as either a hashref or a C<DBIx::Class::ResultSet::CourseSetting> object.

=cut

sub deleteCourseSetting ($self, %args) {
	my $setting         = $self->getCourseSetting(info => $args{info}, as_result_set => 1);
	my $deleted_setting = $setting->delete;

	return $deleted_setting if $args{as_result_set};
	return { $deleted_setting->get_inflated_columns };
}

1;

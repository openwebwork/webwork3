package DB::Schema::ResultSet::Course;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base 'DBIx::Class::ResultSet';

use List::Util qw/first/;

use DB::Utils qw/getCourseInfo getUserInfo/;
use DB::Exception;
use Exception::Class ('DB::Exception::CourseNotFound', 'DB::Exception::CourseExists');

#use DB::TestUtils qw/removeIDs/;
use WeBWorK3::Utils::Settings qw/getDefaultCourseSettings mergeCourseSettings
	getDefaultCourseValues validateCourseSettings/;

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

sub getCourses ($self, $as_result_set = 0) {
	my @courses = $self->search();
	return @courses if $as_result_set;
	return map {
		{ $_->get_inflated_columns };
	} @courses;
}

=head2 getCourse

This gets a single course that is stored in the database in the C<courses> table.

=head3 input

=over

=item *

C<course_info>, a hashref containing either C<course_name> or C<course_id>

=item *

C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

The course either as a C< DBIx::Class::ResultSet::Course> object or a hashref
of the fields. See above.

=cut

sub getCourse ($self, $course_info, $as_result_set = 0) {
	my $course = $self->find(getCourseInfo($course_info));
	DB::Exception::CourseNotFound->throw(course_name => $course_info) unless defined($course);
	return $course if $as_result_set;

	return { $course->get_inflated_columns };
}

=head2 addCourse

Adds a single course to the database in the C<courses> table.

=over

=item *

C<course_info>, a hashref containing either C<course_name> or C<course_id>

=item *

C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

The course either as a C< DBIx::Class::ResultSet::Course> object or a hashref
of the fields. See above.

=cut

sub addCourse ($self, $course_params = {}, $as_result_set = 0) {
	DB::Exception::ParametersNeeded->throw(message => "The parameters must include course_name")
		unless defined($course_params->{course_name});

	# Check if the course exists.  If so throw an error.
	my $course = $self->find({ course_name => $course_params->{course_name} });
	DB::Exception::CourseExists->throw(course_name => $course_params->{course_name}) if defined($course);

	my $params = {};
	for my $field (qw/course_name visible course_dates/) {
		# This should be looked up.
		$params->{$field} = $course_params->{$field} if defined($course_params->{$field});
	}
	$params->{course_settings} = {};

	# Check the parameters.
	my $new_course = $self->create($params);

	return $new_course if $as_result_set;
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

sub deleteCourse ($self, $course_info, $as_result_set = 0) {
	my $course_to_delete = $self->getCourse(getCourseInfo($course_info), 1);

	my $deleted_course = $course_to_delete->delete;
	return $deleted_course if $as_result_set;

	return { $course_to_delete->get_inflated_columns };
}

=head1 updateCourse

This updates a single course that is stored in the database in the C<courses> table.

=head3 input

=over

=item * C<course_name>, a string

=item * A hash of the course parameters to be updated.

=back

=head3 output

The updated course as a C<DBIx::Class::ResultSet::Course> object.

=cut

sub updateCourse ($self, $course_info, $course_params = {}, $as_result_set = 0) {
	my $course = $self->getCourse(getCourseInfo($course_info), 1);
	# TODO: Check the validity of the params.
	my $course_to_return = $course->update($course_params);

	# Need to update params, not blow others away.

	#$course->update($params) unless  scalar(keys %$params) == 0;

	#my $settings = $course->course_setting->update($course_params->{course_settings});

	# Update the course_settings.
	#my $course_settings_from_db = {
	#	$course->course_settings->update($course_params->{course_settings})
	#		->get_inflated_columns
	#};
	#removeIDs($course_settings_from_db);

	return $course_to_return if $as_result_set;
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

sub getUserCourses ($self, $user_info, $as_result_set = 0) {
	my $user = $self->result_source->schema->resultset("User")->getGlobalUser(getUserInfo($user_info), 1);

	my @user_courses = $self->search({ 'course_users.user_id' => $user->user_id }, { prefetch => ['course_users'] });

	#my @user_courses = $course_user->courses();
	return @user_courses if $as_result_set;
	return
		map { { course_name => $_->get_column("course_name"), $_->course_users->first->get_inflated_columns }; }
		@user_courses;
}

=head2 getCourseSettings

This gets the Course Settings for a course

=head3 input

=over

=item * hashref containing info about the course

=item * C<$as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getCourseSettings ($self, $course_info, $as_result_set = 0) {
	my $course = $self->getCourse($course_info, 1);

	my $course_settings  = getDefaultCourseValues();
	my $settings_from_db = { $course->course_settings->get_inflated_columns };
	return mergeCourseSettings($course_settings, $settings_from_db);
}

sub updateCourseSettings ($self, $course_info, $course_settings, $as_result_set = 0) {
	my $course = $self->getCourse($course_info, 1);
	validateCourseSettings($course_settings);

	my $current_settings = { $course->course_settings->get_inflated_columns };
	my $updated_settings = mergeCourseSettings($current_settings, $course_settings);

	my $cs = $course->course_settings->update($updated_settings);
	return mergeCourseSettings(getDefaultCourseValues(), { $cs->get_inflated_columns });
}

1;

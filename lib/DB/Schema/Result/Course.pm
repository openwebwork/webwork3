package DB::Schema::Result::Course;
use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use base qw/DBIx::Class::Core DB::Validation/;
use Mojo::JSON qw/true false/;

=head1 DESCRIPTION

This is the database schema for a Course.

=head2 fields

=over

=item *

C<course_id>: database id (autoincrement integer)

=item *

C<course_name>: name of the course (string)

=item *

C<course_dates>: a JSON object of course dates (currently open and closed)

=item *

C<visible>: a boolean on whether the course is visible or not.

=back

=cut

__PACKAGE__->table('course');

__PACKAGE__->load_components(qw/InflateColumn::Serializer InflateColumn::Boolean Core/);

__PACKAGE__->add_columns(
	course_id => {
		data_type         => 'integer',
		size              => 16,
		is_auto_increment => 1,
	},
	course_name => {
		data_type => 'text',
	},
	course_dates => {
		data_type          => 'text',
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	visible => {
		data_type          => 'boolean',
		default_value      => 1,
		retrieve_on_insert => 1
	}
);

__PACKAGE__->set_primary_key('course_id');

# set up the many-to-many relationship to users
__PACKAGE__->has_many(course_users => 'DB::Schema::Result::CourseUser', 'course_id');
__PACKAGE__->many_to_many(users => 'course_users', 'users');

# set up the one-to-many relationship to problem_sets
__PACKAGE__->has_many(problem_sets => 'DB::Schema::Result::ProblemSet', 'course_id');

# set up the one-to-many relationship to problem_pools
__PACKAGE__->has_many(problem_pools => 'DB::Schema::Result::ProblemPool', 'course_id');

# set up the one-to-one relationship to course settings;
__PACKAGE__->has_one(course_settings => 'DB::Schema::Result::CourseSettings', 'course_id');

=head2 C<valid_fields>

subroutine that returns a hash of the valid fields for json columns

=cut

sub valid_fields ($, $field_name) {
	if ($field_name eq 'course_dates') {
		return {
			open => q{\d+},
			end  => q{\d+}
		};
	} elsif ($field_name eq 'course_params') {
		return { visible => 'bool' };
	} else {
		return {};
	}
}

=head2 C<additional_validation>

subroutine that checks json columns for consistency

=cut

sub additional_validation ($course, $field_name) {
	return 1 if ($field_name ne 'course_dates');

	my $dates = $course->get_inflated_column('course_dates');
	DB::Exception::ImproperDateOrder->throw(message => 'The course dates are not in order')
		unless $dates->{end} > $dates->{open};

	return 1;
}

=head2 C<required>

subroutine that returns a hashref describing the required fields in JSON columns

=cut

sub required ($, $field_name) {
	if ($field_name eq 'set_dates') {
		return { '_ALL_' => [ 'open', 'end' ] };
	} else {
		return {};
	}
}

1;

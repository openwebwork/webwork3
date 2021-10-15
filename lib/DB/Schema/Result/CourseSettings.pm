package DB::Schema::Result::CourseSettings;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

=head1 DESCRIPTION

This is the database schema for a CourseSetting.

=head2 fields

=over

=item *

C<course_settings_id>: database id (autoincrement integer)

=item *

C<course_id>: database id of the course for the setting (foreign key)

=item *

C<general>: a JSON object of general settings

=item *

C<optional>: a JSON object of optional settings

=item *

C<problem_set>: a JSON object that stores settings on the problem set level

=item *

C<problem>: a JSON object that stores settings on the problem level

=item *

C<permissions>: a JSON object that stores settings for permissions

=item *

C<email>: a JSON object that stores email settings

=back

=cut

our @VALID_DATES    = qw/open end/;
our @REQUIRED_DATES = qw//;
our $VALID          = {
	institution => q{.*},
	visible     => q{[01]}
};
our $REQUIRED = { _ALL_ => ['visible'] };

__PACKAGE__->table('course_settings');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	course_settings_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	general => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	optional => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	problem_set => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	problem => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	permissions => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	email => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => "{}",
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('course_settings_id');

__PACKAGE__->belongs_to(course => 'DB::Schema::Result::Course', 'course_id');

1;

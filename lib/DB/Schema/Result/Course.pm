package DB::Schema::Result::Course;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

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

our @VALID_DATES     = qw/open end/;
our @REQUIRED_DATES  = qw//;
our $VALID_PARAMS    = { visible => q{[01]} };
our $REQUIRED_PARAMS = { _ALL_   => ['visible'] };

__PACKAGE__->table('course');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	course_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	course_name => {
		data_type   => 'text',
		is_nullable => 0,
	},
	course_dates => {
		data_type          => 'text',
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	visible => {
		data_type          => 'boolean',
		is_nullable        => 0,
		default_value      => 1,
		retrieve_on_insert => 1
	}
);

__PACKAGE__->inflate_column(
	'visible',
	{
		inflate => sub { return shift ? true : false; },
		deflate => sub { return shift; }
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

1;

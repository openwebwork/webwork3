package DB::Schema::Result::CourseUser;
use base qw/DBIx::Class::Core/;
use strict;
use warnings;

use base qw(DBIx::Class::Core DB::WithParams);

=head1 DESCRIPTION

This is the database schema for a CourseUser.  Note: this table has two purposes 1) a relationship table linking
the course and user tables (many-to-many) and 2) storing information about the user in the given course.

=head2 fields

=over

=item *

C<course_user_id>: database id (primary key, autoincrement integer)

=item *

C<course_id>: the database id of the course (foreign key)

=item *

C<user_id>: the database id of the user (foreign key)

=item *

C<role>: the role of the user (generally a string, but limited to a set of strings)

=item *

C<section>: the section the user is in (string)

=item *

C<recitation>: the recitation the user is in (string)

=item *

C<params>: a JSON object storing parameters.  These are:

=over

=item *

C<comment>: general information that can be stored for the user (string)

=item *

C<useMathQuill>: whether or not the user uses MathQuill (boolean)

=item *

C<useMathView>: whether or not the user uses MathView  (boolean)

=item *

C<displayMode>: the way to display mathematics (Mathjax, etc) a string

=item *

C<status>: the user's status in the course (enrolled, audit, drop), a string

=item *

C<lis_source_did>: information to link an LTI string

=item *

C<useWirisEditor>: whether or not the user uses WirisEditor  (boolean)

=item *

C<showOldAnswers>: whether or not the user shows old answer (boolean)

=back

=back



=cut

__PACKAGE__->table('course_user');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	course_user_id => {
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
	user_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	role => {
		data_type   => 'text',
		size        => 256,
		is_nullable => 1
	},
	section => {
		data_type   => 'text',
		size        => 16,
		is_nullable => 1,
	},
	recitation => {
		data_type   => 'text',
		size        => 16,
		is_nullable => 1,
	},
	# Store params as a JSON object.
	course_user_params => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'Boolean::JSON',
		serializer_options => { boolean_fields => ['useMathQuill', 'showOldAnswers'] }
		# serializer_options => { utf8 => 1, allow_blessed => 1, convert_blessed => 1 }
	}
);

sub valid_params {
	return {
		comment        => q{.*},
		useMathQuill   => q{[01]},
		displayMode    => q{.*},
		status         => q{[A-Z]},
		lis_source_did => q{.*},
		showOldAnswers => q{[01]}
	};
}

sub required_params {
	return {};
}

__PACKAGE__->set_primary_key('course_user_id');
__PACKAGE__->add_unique_constraint([qw/course_id user_id/]);

__PACKAGE__->belongs_to(users   => 'DB::Schema::Result::User',   'user_id');
__PACKAGE__->belongs_to(courses => 'DB::Schema::Result::Course', 'course_id');

__PACKAGE__->has_many(user_sets => 'DB::Schema::Result::UserSet', 'course_user_id');

1;

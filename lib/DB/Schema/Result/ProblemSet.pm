package DB::Schema::Result::ProblemSet;
use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base qw(DBIx::Class::Core);

=head1 DESCRIPTION

This is the database schema for a ProblemSet, which is the super class for a
HomeworkSet, Quiz and ReviewSet.

=head2 fields

=over

=item *

C<set_id>: database id (autoincrement integer)

=item *

C<set_name>: name of the set

=item *

C<course_id>: id of the course the set is in (foreign key)

=item *

C<type>: the type of problem set (see below)

=item *

C<set_visible>: (boolean) visiblility of the set to a student

=item *

C<set_dates>: a hash of dates related to the problem set.  Note: different types have
different date fields.

=item *

C<set_params>: a hash of additional parameters of the problem set.  Note: different problem set types
have different params fields.

=back

=head3 Problem Set types

The three subtypes of a C<ProblemSet> are

=over

=item *

L<DB::Schema::Result::ProblemSet::HWSet> which gives properties common to homework sets.

=item *

L<DB::Schema::Result::ProblemSet::Quiz> which gives properties common to quizzes.

=item *

L<DB::Schema::Result::ProblemSet::ReviewSet> which gives properties common to review sets.

=back

=cut

__PACKAGE__->load_components(qw/DynamicSubclass Core/);

__PACKAGE__->table('problem_set');

__PACKAGE__->load_components(qw/DynamicSubclass Core/, qw/InflateColumn::Serializer Core/);

__PACKAGE__->add_columns(
	set_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	set_name => {
		data_type   => 'varchar',
		size        => 256,
		is_nullable => 0,
	},
	course_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	type => {
		data_type     => 'int',
		default_value => 1,
		size          => 8
	},
	set_visible => {
		data_type     => 'boolean',
		default_value => 1,
		is_nullable   => 0
	},
	# Store dates as a JSON object.
	set_dates => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'Boolean::JSON',
		serializer_options => { boolean_fields => ['enable_reduced_scoring'] }
	},
	# Store params as a JSON object.
	# The boolean_fields from any subclass needs to be added here.
	set_params => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'Boolean::JSON',
		serializer_options => { boolean_fields => [ 'hide_hint', 'timed', 'problem_randorder', 'test_param' ] }
	}
);

__PACKAGE__->inflate_column(
	'set_visible',
	{
		inflate => sub { return shift ? Mojo::JSON->true : Mojo::JSON->false; },
		deflate => sub { return shift; }
	}
);

__PACKAGE__->inflate_column(
	'set_visible',
	{
		inflate => sub { return shift ? Mojo::JSON->true : Mojo::JSON->false; },
		deflate => sub { return shift; }
	}
);

# This defines the non-abstract classes of ProblemSets.

__PACKAGE__->typecast_map(
	type => {
		1 => 'DB::Schema::Result::ProblemSet::HWSet',
		2 => 'DB::Schema::Result::ProblemSet::Quiz',
		3 => 'DB::Schema::Result::ProblemSet::JITAR',
		4 => 'DB::Schema::Result::ProblemSet::ReviewSet',
	}
);

__PACKAGE__->set_primary_key('set_id');
__PACKAGE__->add_unique_constraint([qw/course_id set_name/]);

__PACKAGE__->belongs_to(courses => 'DB::Schema::Result::Course', 'course_id');
__PACKAGE__->has_many(problems  => 'DB::Schema::Result::SetProblem', 'set_id');
__PACKAGE__->has_many(user_sets => 'DB::Schema::Result::UserSet',    'set_id');

=head2 set_type

returns the type (HW, Quiz, JITAR, REVIEW) of the problem set

=cut

sub set_type ($set) {
	my %set_type_rev = reverse %{$DB::Schema::ResultSet::ProblemSet::SET_TYPES};
	return $set_type_rev{ $set->type };
}
1;

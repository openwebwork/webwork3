package DB::Schema::Result::ProblemSet;
use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use Mojo::JSON qw/true false/;
use DB::Utils qw/updateAllFields/;
use base qw/DBIx::Class::Core/;

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
		is_auto_increment => 1,
	},
	set_name => {
		data_type => 'varchar',
		size      => 256,
	},
	course_id => {
		data_type => 'integer',
		size      => 16,
	},
	type => {
		data_type          => 'int',
		size               => 8,
		default_value      => 1,
		retrieve_on_insert => 1,
	},
	set_visible => {
		data_type          => 'boolean',
		default_value      => 0,
		retrieve_on_insert => 1
	},
	# Store dates as a JSON object.
	set_dates => {
		data_type          => 'text',
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	# Store params as a JSON object.
	set_params => {
		data_type          => 'text',
		default_value      => '{}',
		retrieve_on_insert => 1,
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->inflate_column(
	'set_visible',
	{
		inflate => sub { return shift ? true : false; },
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

=head2 validateOverrides

when called on a problem_set with proposed update hash, loops through the problem_set fields that
require validation, stripping out any unchanged values from the proposed update and then validating
the set works with the proposed overrides.

=cut

sub validateOverrides ($set, $updates) {
	foreach my $column_name (qw/set_dates set_params/) {
		$set->_stripUnchanged($updates, $column_name);
		$set->set_inflated_column(
			$column_name => updateAllFields($set->get_inflated_column($column_name), $updates->{$column_name}));
		$set->validate($column_name);
	}
	$set->discard_changes;
	return;
}

=head2 _stripUnchanged

when called on a problem_set with proposed update hash containing $column_name as a key
will iteratively compare key-values in the update hash to existing values on the
field_name column of the problem_set, deleting (in-place!) any key-value pairs that are
unchanged from the problem_set

=cut

sub _stripUnchanged ($set, $updates, $column_name) {
	foreach (keys %{ $set->valid_fields($column_name) }) {
		next unless exists($updates->{$column_name}{$_});
		my $defined   = defined($updates->{$column_name}{$_}) ? 1 : 0;
		my $is_truthy = $updates->{$column_name}{$_}          ? 1 : 0;
		my $was_undef = defined($set->$column_name->{$_})     ? 0 : 1;

		# use eq since numbers stringify and strings don't numerify ;P
		my $different = ($defined && ($was_undef || $updates->{$column_name}{$_} ne $set->$column_name->{$_})) ? 1 : 0;
		if (ref($set->$column_name->{$_}) =~ m/boolean/i) {
			delete $updates->{$column_name}{$_} unless $different;
		} else {
			delete $updates->{$column_name}{$_} unless $is_truthy && $different;
		}
	}
	return;
}

1;

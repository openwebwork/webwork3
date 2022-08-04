package DB::Schema::Result::UserSet;
use base qw(DBIx::Class::Core DB::Validation);

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

=head1 DESCRIPTION

This is the database schema for a UserSet, which plays two roles:

=item 1

This overrides any ProblemSet for a particular user

=item 2

This is the super class for a UserSet version of a HomeworkSet, Quiz and ReviewSet.

=head2 fields

=over

=item *

C<set_id>: database id (autoincrement integer)

=item *

C<set_name>: name of the set

=item *

C<course_id>: id of the course the set is in (foreign key)

=item *

C<set_visible>: (boolean) visiblility of the set to a student

=item *

C<set_version>: (non-negative integer) the version of the user set.

=item *

C<set_dates>: a hash of dates related to the problem set.  Note: different types
have different date fields.

=item *

C<set_params>: a hash of additional parameters of the problem set.  Note: different problem set
types have different params fields.

=back

=cut

__PACKAGE__->table('user_set');

__PACKAGE__->load_components('InflateColumn::Serializer', 'Core');

__PACKAGE__->add_columns(
	user_set_id => {
		data_type         => 'integer',
		size              => 16,
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	set_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	course_user_id => {
		data_type   => 'integer',
		size        => 16,
		is_nullable => 0,
	},
	set_version => {
		data_type     => 'integer',
		size          => 16,
		is_nullable   => 0,
		default_value => 0,
	},
	set_visible => {
		data_type   => 'boolean',
		is_nullable => 1
	},
	# Store dates as a JSON object.
	set_dates => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	},
	# Store params as a JSON object.
	set_params => {
		data_type          => 'text',
		size               => 256,
		is_nullable        => 0,
		default_value      => '{}',
		serializer_class   => 'JSON',
		serializer_options => { utf8 => 1 }
	}
);

__PACKAGE__->set_primary_key('user_set_id');
__PACKAGE__->add_unique_constraint([qw/set_id course_user_id set_version/]);
__PACKAGE__->belongs_to(
	course_users => 'DB::Schema::Result::CourseUser',
	{ 'foreign.course_user_id' => 'self.course_user_id' }
);
__PACKAGE__->belongs_to(problem_set => 'DB::Schema::Result::ProblemSet', 'set_id');
__PACKAGE__->has_many(user_problems => 'DB::Schema::Result::UserProblem', 'user_set_id');

# See https://metacpan.org/dist/DBIx-Class/view/lib/DBIx/Class/Manual/Cookbook.pod#Dynamic-Sub-classing-DBIx::Class-proxy-classes
sub inflate_result {
	my $self = shift;
	my $ret  = $self->next::method(@_);
	# bless into subclass based on relation to problem_set
	return bless $ret, (ref($ret->problem_set) =~ s/:ProblemSet:/:UserSet:/r);
}

sub set_type {
	my %set_type_rev = reverse %{$DB::Schema::ResultSet::ProblemSet::SET_TYPES};
	return $set_type_rev{ shift->problem_set->type };
}

1;

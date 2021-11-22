package DB::Schema::Result::UserSet;
use base qw(DBIx::Class::Core DB::WithParams DB::WithDates);

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

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

C<type>: the type of problem set (see below)

=item *

C<set_visible>: (boolean) visiblility of the set to a student

=item *

C<dates>: a hash of dates related to the problem set.  Note: different types
have different date fields.

=item *

C<params>: a hash of additional parameters of the problem set.  Note: different problem set
types have different params fields.

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
		default_value => 1,
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
__PACKAGE__->belongs_to(problem_sets => 'DB::Schema::Result::ProblemSet', 'set_id');

# This defines the non-abstract classes of ProblemSets.

# __PACKAGE__->typecast_map(
# 	type => {
# 		1 => 'DB::Schema::Result::UserSet::HWSet',
# 		2 => 'DB::Schema::Result::UserSet::Quiz',
# 		3 => 'DB::Schema::Result::UserSet::JITAR',
# 		4 => 'DB::Schema::Result::UserSet::ReviewSet',
# 	}
# );

my $set_type = {
	1 => 'DB::Schema::Result::ProblemSet::HWSet',
	2 => 'DB::Schema::Result::ProblemSet::Quiz',
	3 => 'DB::Schema::Result::ProblemSet::JITAR',
	4 => 'DB::Schema::Result::ProblemSet::ReviewSet'
};

sub valid_params ($type) {
	## no critic
	my $params = eval $set_type->{$type} . '::valid_params';
	## use critic
	return $params;
}

sub required_params ($type) {
	## no critic
	my $params = eval $set_type->{$type} . '::required_params';
	## use critic
	return $params;
}

sub valid_dates ($type) {
	## no critic
	my $params = eval $set_type->{$type} . '::valid_dates';
	## use critic
	return $params;
}

sub required_dates ($type) {
	## no critic
	my $params = eval $set_type->{$type} . '::required_dates';
	## use critic
	return $params;
}

1;

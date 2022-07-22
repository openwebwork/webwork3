package DB::Schema::ResultSet::Attempt;
use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use Clone qw/clone/;
use base 'DBIx::Class::ResultSet';

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo getUserInfo updateAllFields/;

use Clone qw/clone/;

use Exception::Class (
	'DB::Exception::UserProblemExists',
	'DB::Exception::UserProblemNotFound',
	'DB::Exception::SetProblemNotFound'
);

=head1 DESCRIPTION

This is the functionality of an Attempt in WeBWorK, used to record informaiton when
a user submits a problems.  This package is based on
C<DBIx::Class::ResultSet>.

=head2 getAttempt

Get a single row of the  C<attempt> table.

=head3 input

A hash with the following fields:

=over

=item * C<info>, a hashref of

=over
=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

=back

=item * C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of user problems as a C<DBIx::Class::ResultSet::UserProblem> object
if C<as_result_set> is true.  Otherwise an array of hash_ref of the fields.
See <DB::Schema::Result::User::Problem> for information on the fields.  If C<merged>
is true, the return is a merged hashref.

=cut

sub getAttempts ($self, %args) {
	my $user_problem = $self->rs('UserProblem')->getUserProblem(info => $args{info}, as_result_set => 1);

	my @attempts = $self->search({ user_problem_id => $user_problem->user_problem_id });

	return @attempts if $args{as_result_set};
	my @attempts_to_return = ();
	for my $attempt (@attempts) {
		push(@attempts_to_return, { $attempt->get_inflated_columns });
	}
	return @attempts_to_return;
}

=head2 addAttempt

Add an Attempt to the C<attempt> table.

=head3 input

A hash with the following fields:

=over

=item * C<info>, a hashref of

=over
=item - either a C<course name> or C<course_id>.
=item - either a C<username> or C<user_id>
=item - either a C<set_nam> or C<set_id>
=item - either a C<problem_number> or C<problem_id>

=back

=item * C<params>, a hashref containing

=over
=item - C<scores>, an arrayref of scores (as numbers)
=item - C<answers>, an arrayref of answers (as strings)
=item - C<comments> an arrayref of comments (as strings)
=back

=item * C<as_result_set>, a boolean if the return is to be a result_set

=back

=head3 output

An array of user problems as a C<DBIx::Class::ResultSet::UserProblem> object
if C<as_result_set> is true.  Otherwise an array of hash_ref of the fields.
See <DB::Schema::Result::User::Problem> for information on the fields.  If C<merged>
is true, the return is a merged hashref.

=cut

sub addAttempt ($self, %args) {
	my $user_problem = $self->rs('UserProblem')->getUserProblem(info => $args{params}, as_result_set => 1);

	my $params = clone $args{params};

	# Remove some parameters that are not in the UserSet database, but may be passed in.
	for my $key (qw/username user_id course_name set_name set_id set_problem_id problem_number problem_version/) {
		delete $params->{$key} if defined $params->{$key};
	}

	# need to check parameters have the right form.
	my $attempt_to_add = $self->new($params);

	my $attempt = $user_problem->add_to_attempts($params);
	return $args{as_result_set} ? $attempt : { $attempt->get_inflated_columns };
}

# This is a small subroutine to shorten access to the db.
sub rs ($self, $table) {
	return $self->result_source->schema->resultset($table);
}

1;

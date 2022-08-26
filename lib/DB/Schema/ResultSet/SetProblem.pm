package DB::Schema::ResultSet::SetProblem;

use strict;
use warnings;
use feature 'signatures';
no warnings qw/experimental::signatures/;

use Clone qw/clone/;
use base 'DBIx::Class::ResultSet';

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo updateAllFields/;

=head1 DESCRIPTION

This is the functionality of a Problem in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for problems in Problem sets.

=head2 getGlobalProblems

This gets a list of all problems stored in the database in the C<problems> table.

=head3 input, a hash of options

=over
=item - C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 output

An array of problems as either a hashref or a  C<DBIx::Class::ResultSet::Problem> object

=cut

sub getGlobalProblems ($self, %args) {
	my @problems = $self->search({});

	return @problems if $args{as_result_set};
	return map {
		{
			$_->get_inflated_columns, set_name => $_->problem_set->set_name
		};
	} @problems;
}

# CRUD for problems in a course

=head1 getProblems

This gets all problems in a given course.

=head3 input,  a hash of options

=over

=item * C<info>, either a course name or course_id.

For example, C<{ course_name => 'Precalculus'}> or C<{course_id => 3}>

=item - C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or course_id doesn't exist, an error will be thrown.

=head3 output

An array of Problems (as hashrefs) or an array of C<DBIx::Class::ResultSet::Problem>

=cut

sub getProblems ($self, %args) {
	my $course = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);

	my @problems =
		$self->search({ 'problem_set.course_id' => $course->course_id }, { join => [qw/problem_set/] });

	return @problems if $args{as_result_set};
	return map {
		{ $_->get_inflated_columns };
	} @problems;
}

=head1 getSetProblems

This gets all problems in a given set

=head3 input,  a hash of options

=over

=item * C<info>, a hash with

=over
=item - C<course_name> or C<course_id>
=item - C<set_name> or C<set_id>

=back

For example, C<{ course_name => 'Precalculus', set_id => 4}>
or C<{course_id => 3, set_name => 'HW #1'}>

=item * C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or set doesn't exist, an exception will be thrown.

=head3 output

An array of Problems (as hashrefs) or an array of C<DBIx::Class::ResultSet::Problem>

=cut

sub getSetProblems ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{info}, as_result_set => 1);
	my @problems    = $self->search({ 'set_id' => $problem_set->set_id });

	return \@problems if $args{as_result_set};
	return map {
		{ $_->get_inflated_columns };
	} @problems;
}

=head2 getSetProblem

This gets a single problem from a given course and problem

=head3 input,  a hash of options

=over

=item * C<info>, a hash with

=over
=item - C<course_name> or C<course_id>
=item - C<set_name> or C<set_id>
=item - C<problem_number> or C<set_problem_id>

=back

For example, C<{ course_name => 'Precalculus', set_id => 4}>
or C<{course_id => 3, set_name => 'HW #1'}>

=item * C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or set doesn't exist, an exception will be thrown.

=head3 output

An array of Problems (as hashrefs) or an array of C<DBIx::Class::ResultSet::Problem>

=cut

sub getSetProblem ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{info}, as_result_set => 1);

	my $problem = $problem_set->problems->find(getProblemInfo($args{info}));

	DB::Exception::SetProblemNotFound->throw(
		message => 'the problem with '
			. (
				$args{info}->{problem_number}
				? 'problem number ' . $args{info}->{problem_number}
				: 'set_problem id: ' . $args{info}->{set_problem_id}
			)
			. ' is not found for set: '
			. $problem_set->set_name
			. ' is the course: '
			. $problem_set->course->course_name
	) unless $problem;

	return $problem if $args{as_result_set};
	return { $problem->get_inflated_columns };
}

=head2 addSetProblem

Add a single problem to an existing problem set within a course

=head3 input,  a hash of options

=over

=item * C<info>, a hash with

=over
=item - C<course_name> or C<course_id>
=item - C<set_name> or C<set_id>

=back

For example, C<{ course_name => 'Precalculus', set_id => 4}>
or C<{course_id => 3, set_name => 'HW #1'}>

=item * C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or set doesn't exist, an exception will be thrown.

=head3 output

An array of Problems (as hashrefs) or an array of C<DBIx::Class::ResultSet::Problem>

=cut

=head3 Note

=over

=item * If either the problem set or course does not exist an error will be thrown

=item * If the problem parameters are not valid, an error will be thrown.

=back

=cut

sub addSetProblem ($self, %args) {
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(info => $args{params}, as_result_set => 1);
	my $params      = clone $args{params};

	# Remove some parameters that are not in the database, but may be passed in,
	# including set_problem_id which should not have a value if being added.
	for my $key (qw/set_problem_id course_name course_id set_name/) {
		delete $params->{$key} if defined $params->{$key};
	}

	# set the problem number to one more than the set's largest
	$params->{problem_number} = 1 + ($problem_set->problems->get_column('problem_number')->max // 0);
	$params->{problem_params}{weight} = 1 unless defined($params->{problem_params}{weight});

	$self->checkProblemParams($params);

	my $added_problem = $problem_set->add_to_problems($params);
	return $args{as_result_set} ? $added_problem : { $added_problem->get_inflated_columns };
}

sub checkProblemParams ($self, $params) {

	# Check that the problem_number field is a positive number.
	DB::Exception::InvalidParameter->throw(message => 'The problem_number must be a positive integer')
		unless defined $params->{problem_number} && $params->{problem_number} =~ /^\d+$/;

	my $problem_to_add = $self->new($params);
	$problem_to_add->validate('problem_params');
	return 1;
}

=head2 updateSetProblem

update a single problem in a problem set within a course

=head3 input,  a hash of options

=over

=item * C<info>, a hash with

=over
=item - C<course_name> or C<course_id>
=item - C<set_name> or C<set_id>

=back

For example, C<{ course_name => 'Precalculus', set_id => 4}>
or C<{course_id => 3, set_name => 'HW #1'}>


=item * C<params>, a hash with fields/parameters from C<DB::Schema::Result::Problem>


=item * C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or set doesn't exist, an exception will be thrown.

=head3 output

A single Problem (as hashrefs) or an object of class C<DBIx::Class::ResultSet::Problem>

=cut

=head3 Note

=over

=item * If either the problem set or course does not exist an error will be thrown

=item * If the problem parameters are not valid, an error will be thrown.

=back

=cut

sub updateSetProblem ($self, %args) {
	my $problem = $self->getSetProblem(info => $args{info}, as_result_set => 1);
	my $params  = updateAllFields({ $problem->get_inflated_columns }, $args{params});

	# Check that the new params are valid.
	my $updated_problem = $self->new($params);
	$self->checkProblemParams($params);

	my $problem_to_return = $problem->update($params);
	return $args{as_result_set} ? $problem_to_return : { $problem_to_return->get_inflated_columns };
}

=head2 deleteSetProblem

delete a single problem to an existing problem set within a course

=head3 input,  a hash of options

=over

=item * C<info>, a hash with

=over
=item - C<course_name> or C<course_id>
=item - C<set_name> or C<set_id>
=item - C<problem_number> or C<set_problem_id>

=back

For example, C<{ course_name => 'Precalculus', set_id => 4}>
or C<{course_id => 3, set_name => 'HW #1'}>

=item * C<as_result_set>, a boolean.  If true this result an array of C<DBIx::Class::ResultSet::ProblemSet>
if false, an array of hashrefs of ProblemSet.

=back

=head3 notes:
if either the course or set doesn't exist, an exception will be thrown.

=head3 output

A problem (as hashrefs) or an object of class C<DBIx::Class::ResultSet::Problem>

=cut

sub deleteSetProblem ($self, %args) {
	my $set_problem = $self->getSetProblem(info => $args{info}, as_result_set => 1);
	my $problem_set = $self->rs('ProblemSet')->getProblemSet(
		info => {
			course_id => $set_problem->problem_set->course_id,
			set_id    => $set_problem->set_id
		},
		as_result_set => 1
	);

	my $problem = $problem_set->search_related('problems', getProblemInfo($args{info}))->single;

	my $deleted_problem = $problem->delete;

	return $deleted_problem if $args{as_result_set};
	return { $deleted_problem->get_inflated_columns };
}

# just a small subroutine to shorten access to the db.

sub rs ($self, $table) {
	return $self->result_source->schema->resultset($table);
}

1;

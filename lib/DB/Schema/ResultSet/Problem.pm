package DB::Schema::ResultSet::Problem;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dumper;

# use List::Util qw/first/;

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo/;

=head1 DESCRIPTION

This is the functionality of a Course in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for anything on the
global courses.

=head2 getGlobalProblems

This gets a list of all problems stored in the database in the C<problems> table.

=head3 input

C<$as_result_set>, a boolean if the return is to be a result_set

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref.

=cut

sub getGlobalProblems {
	my ($self, $as_result_set) = @_;
	my @problems = $self->search( {},
		{
			join => 'problem_set',
			'+select' => ['problem_set.set_name'],
		}
	);
	return @problems if $as_result_set;
	return map {
		{ $_->get_inflated_columns, $_->problem_set->get_inflated_columns };
	} @problems;
}

###
#
# CRUD for problems in a course
#
###

=head1 getProblems

This gets all problems in a given course.

=head3 input

=over

=item * C<params>, a hashref containing:

=over

=item - C<course_name>, the name of an existing course or C<course_id>.

=back

=back

=head3 notes:
if either the course or username doesn't exist, an error will be thrown.

=head3 output

An arrayref of the problems.

=cut

sub getProblems {
	my ($self, $course_info, $as_result_set) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse($course_info, 1);

	my @problems =
		$self->search({ 'problem_set.course_id' => $course->course_id }, { prefetch => [qw/problem_set/] });

	return \@problems if $as_result_set;
	return map {
		{
			$_->get_inflated_columns, set_name => $_->problem_set->set_name
		};
	} @problems;

}

sub getSetProblems {
	my ($self, $course_set_info, $as_result_set) = @_;

	my $course_rs      = $self->result_source->schema->resultset("Course");
	my $problem_set_rs = $self->result_source->schema->resultset("ProblemSet");

	my $problem_set = $problem_set_rs->getProblemSet($course_set_info, 1);
	my @problems    = $self->search({ 'set_id' => $problem_set->set_id });

	return \@problems if $as_result_set;
	return map {
		{ $_->get_inflated_columns };
	} @problems;
}

=head2 getSetProblem

This gets a single problem from a given course and problem

=head3 Input

A hashref containing

=over

=item * The course_id or course_name

=item * The set_id or set_name

=item * The problem_id or problem_number

=back

=cut

sub getSetProblem {
	my ($self, $course_set_problem_info, $as_result_set) = @_;
	my $course_set_info = { %{ getCourseInfo($course_set_problem_info) }, %{ getSetInfo($course_set_problem_info) } };
	my $problem_set_rs  = $self->result_source->schema->resultset("ProblemSet");
	my $problem_set     = $problem_set_rs->getProblemSet($course_set_info, 1);

	my $problem_info = getProblemInfo($course_set_problem_info);
	my $problem      = $problem_set->problems->find($problem_info);

	return $problem if $as_result_set;
	return { $problem->get_inflated_columns };
}

=head2 addSetProblem

Add a single problem to an existing problem set within a course

=head3 Note

=over

=item * If either the problem set or course does not exist an error will be thrown

=item * If the problem parameters are not valid, an error will be thrown.

=back

=cut

sub addSetProblem {
	my ($self, $course_set_info, $new_problem_params, $as_result_set) = @_;
	my $problem_set = $self->result_source->schema->resultset("ProblemSet")->getProblemSet($course_set_info, 1);
	# set the problem number to one more than the set's largest
	$new_problem_params->{problem_number} = 1 + ($problem_set->problems->get_column('problem_number')->max // 0);

	my $problem_to_add = $self->new($new_problem_params);
	$problem_to_add->validParams(undef, 'problem_params');

	my $added_problem = $problem_set->add_to_problems($new_problem_params);
	return $as_result_set ? $added_problem : { $added_problem->get_inflated_columns };
}

=head2 deleteSetProblem

delete a single problem to an existing problem set within a course

=head3 Note

=over

=item * If either the problem set or course does not exist an error will be thrown

=item * If the problem parameters are not valid, an error will be thrown.

=back

=cut

sub deleteSetProblem {
	my ($self, $course_set_problem_info, $problem_params, $as_result_set) = @_;
	my $set_problem = $self->getSetProblem($course_set_problem_info, 1);
	my $problem_set = $self->result_source->schema->resultset("ProblemSet")
		->getProblemSet({ course_id => $set_problem->problem_set->course_id, set_id => $set_problem->set_id }, 1);

	my $problem = $problem_set->search_related("problems", getProblemInfo($course_set_problem_info))->single;

	my $deleted_problem = $problem->delete;

	return $deleted_problem if $as_result_set;
	return { $deleted_problem->get_inflated_columns };

}

=head2 deleteSetProblem

This deletes the problem with given course and set

=cut

1;

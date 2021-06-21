package DB::Schema::ResultSet::Problem;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dump qw/dd dump/;

# use List::Util qw/first/;

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo/;

=pod
 
=head1 DESCRIPTION
 
This is the functionality of a Course in WeBWorK.  This package is based on 
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for anything on the 
global courses.  
 
=cut

=pod
=head2 getGlobalProblems

This gets a list of all problems stored in the database in the <code>problems</codes> table. 

=head3 input 

<code>$as_result_set</code>, a boolean if the return is to be a result_set

=head3 output 

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object
if <code>$as_result_set</code> is true.  Otherwise an array of hash_ref.  

=cut

sub getGlobalProblems {
	my ( $self, $as_result_set ) = @_;
	my @problems = $self->search();
	return @problems if $as_result_set;
	return map {
		{ $_->get_inflated_columns };
	} @problems;
}

###
#
# CRUD for problems in a course
#
###

=pod
=head1 getProblems

This gets all problems in a given course. 

=head3 input 

=item * 
<code>params</code>, a hashref containing:
=item -
<code>course_name</code>, the name of an existing course or
<code>course_id</code>.

=head3 notes:
if either the course or login doesn't exist, an error will be thrown. 

=head3 output 

An arrayref of the problems. 

=cut

sub getProblems {
	my ( $self, $course_info, $as_result_set ) = @_;
	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course    = $course_rs->getCourse( $course_info, 1 );

	my @problems =
		$self->search( { 'problem_set.course_id' => $course->course_id }, { prefetch => [qw/problem_set/] } );

	return \@problems if $as_result_set;
	return map {
		{
			$_->get_inflated_columns, set_name => $_->problem_set->set_name
		};
	} @problems;

}

sub getSetProblems {
	my ( $self, $course_set_info, $as_result_set ) = @_;

	my $course_rs      = $self->result_source->schema->resultset("Course");
	my $problem_set_rs = $self->result_source->schema->resultset("ProblemSet");

	my $set      = $problem_set_rs->getProblemSet( $course_set_info, 1 );
	my @problems = $self->search( { 'set_id' => $set->set_id } );

	return \@problems if $as_result_set;
	return map {
		{ $_->get_inflated_columns };
	} @problems;
}

=pod

=head2 getSetProblem 

This gets a single problem from a given course and problem 

=head3 Input

A hashref containing
=item *
The course_id or course_name
=item *
The set_id or set_name 
=item * 
The problem_id or problem_number

=cut

sub getSetProblem {
	my ( $self, $course_set_problem_info, $as_result_set ) = @_;
	my $course_set_info = { %{ getCourseInfo($course_set_problem_info) }, %{ getSetInfo($course_set_problem_info) } };
	my $problem_set_rs  = $self->result_source->schema->resultset("ProblemSet");
	my $set             = $problem_set_rs->getProblemSet( $course_set_info, 1 );

	my $problem_info = getProblemInfo($course_set_problem_info);
	my $problem      = $set->problems->find($problem_info);

	return { $problem->get_inflated_columns };
}

=pod

=head2 addSetProblem 

Add a single problem to an existing problem set within a course


=head3 Note

=item * 
If either the problem set or course does not exist an error will be thrown
=item * 
If the problem parameters are not valid, an error will be thrown. 

=cut

sub addSetProblem {
	my ( $self, $course_set_info, $new_set_params, $as_result_set ) = @_;

	my $course_rs      = $self->result_source->schema->resultset("Course");
	my $problem_set_rs = $self->result_source->schema->resultset("ProblemSet");

	my $set = $problem_set_rs->getProblemSet( $course_set_info, 1 );

	my $problem_to_add = $self->new($new_set_params);
	$problem_to_add->validParams();
	my $added_problem = $set->add_to_problems($new_set_params);
	return $added_problem if $as_result_set;
	return { $added_problem->get_inflated_columns };

}

=pod

=head2 deleteSetProblem 

delete a single problem to an existing problem set within a course


=head3 Note

=item * 
If either the problem set or course does not exist an error will be thrown
=item * 
If the problem parameters are not valid, an error will be thrown. 

=cut

sub deleteSetProblem {
	my ( $self, $course_set_problem_info, $problem_params, $as_result_set ) = @_;
	my $course_set_info = { %{ getCourseInfo($course_set_problem_info) }, %{ getSetInfo($course_set_problem_info) } };
	my $problem_set_rs  = $self->result_source->schema->resultset("ProblemSet");
	my $set             = $problem_set_rs->getProblemSet( $course_set_info, 1 );

	my $problem = $set->search_related( "problems", getProblemInfo($course_set_problem_info) )->single;

	my $deleted_problem = $problem->delete;

	return $deleted_problem if $as_result_set;
	return { $deleted_problem->get_inflated_columns };

}

sub addPoolProblem {
	my ( $self, $course_set_info, $new_set_params, $as_result_set ) = @_;
}

=pod
=head2 deleteSetProblem

This deletes the problem with given course and set

=cut

1;

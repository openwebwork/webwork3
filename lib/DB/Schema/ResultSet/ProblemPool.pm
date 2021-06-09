package DB::Schema::ResultSet::ProblemPool;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use Carp;
use Data::Dump qw/dd dump/;
use Scalar::Util qw/reftype/;

use DB::Utils qw/getCourseInfo parseCourseInfo getPoolInfo/;


=pod

=head1 DESCRIPTION

This is the functionality of a Course in WeBWorK.  This package is based on
<code>DBIx::Class::ResultSet</code>.  The basics are a CRUD for anything on the
global courses.

=cut

=pod
=head2 getAllProblemPools

This gets a list of all problems stored in the database in the <code>problems</codes> table.

=head3 input

<code>$as_result_set</code>, a boolean if the return is to be a result_set

=head3 output

An array of courses as a <code>DBIx::Class::ResultSet::Course</code> object
if <code>$as_result_set</code> is true.  Otherwise an array of hash_ref.

=cut

sub getAllProblemPools {
	my ($self, $as_result_set)  = @_;
	my @problem_pools = $self->search({},
		{prefetch => [qw/courses/]});
	return @problem_pools if $as_result_set;
	return map { {$_->get_inflated_columns,$_->courses->get_inflated_columns}; } @problem_pools;
}

=pod
=head2 getProblemPools

Get all problem pools for a given course

=cut

sub getProblemPools {
	my ($self,$course_info,$as_result_set) = @_;
	my $search_params = parseCourseInfo($course_info); ## return a hash of course info

	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse($course_info,1);


	my @pools = $self->search({'courses.course_id' => $course->course_id},{prefetch => [qw/courses/]});

	return \@pools if $as_result_set;
	return map { {$_->get_inflated_columns,$_->courses->get_inflated_columns}; } @pools;

}

####
#
# CRUD for a single ProblemPool
#
####
=pod
=head2 getProblemPool

Get a single problem pool for a given course

=cut

sub getProblemPool {
	my ($self,$course_pool_info,$as_result_set) = @_;
	my $course_info = getCourseInfo($course_pool_info);
	parseCourseInfo($course_info); ## return a hash of course info

	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse($course_info,1);

	my $search_info = getPoolInfo($course_pool_info);
	$search_info->{'courses.course_id'} = $course->course_id;



	my $pool = $self->find($search_info,{prefetch => [qw/courses/]});

	unless($pool) {
		my $pool_info = getPoolInfo($course_pool_info);
		my $course_name = $course->course_name;
		croak "The pool with info $pool_info in course $course_name does not exist";
	}

	return $pool if $as_result_set;
	return {$pool->get_columns,$pool->courses->get_columns};

}



=pod
=head2 addProblemPool

Add a problem pool for a given course

=cut

sub addProblemPool {
	my ($self,$course_info,$pool_params, $as_result_set) = @_;
	my $search_params = parseCourseInfo($course_info); ## return a hash of course info

	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->getCourse($course_info,1);
	my $course_name = $course->course_name;

	croak "The pool_name is missing from the parameters" unless defined($pool_params->{pool_name});

	my $existing_pool = $self->find(
						{
							'courses.course_id' => $course->course_id,
							pool_name => $pool_params->{pool_name}
						},{prefetch => [qw/courses/]});

	croak "The problem pool with name: \"$pool_params->{pool_name}\" in course $course_name already exists" if defined($existing_pool);

	my $pool_to_add =$self->new($pool_params);

	my $problem_pool = $course->add_to_problem_pools({$pool_to_add->get_columns});

	return $problem_pool if $as_result_set;
	return {$problem_pool->get_columns,$problem_pool->courses->get_columns};

}

=pod
=head2 updateProblemPool

updates the parameters of an existing problem pool

=cut

sub updateProblemPool {
	my ($self,$course_pool_info,$pool_params, $as_result_set) = @_;

	my $pool = $self->getProblemPool($course_pool_info,1);

	croak "The problem pool does not exist" unless defined($pool);

	# create a new problem pool to check for valid fields
	my $new_pool = $self->new($pool_params);

	my $updated_pool = $pool->update($pool_params);

	return $updated_pool if $as_result_set;
	return {$updated_pool->get_columns,$updated_pool->courses->get_columns};
}

=pod
=head2 updateProblemPool

updates the parameters of an existing problem pool

=cut

sub deleteProblemPool {
	my ($self,$course_pool_info,$pool_params, $as_result_set) = @_;

	my $pool = $self->getProblemPool($course_pool_info,1);

	croak "The problem pool does not exist" unless defined($pool);


	my $deleted_pool = $pool->delete();

	return $deleted_pool if $as_result_set;
	return {$deleted_pool->get_columns,$deleted_pool->courses->get_columns};
}

=pod
=head2 addProblemToPool

This adds a problem or arrayref of problems to an existing problem pool.

=cut


sub addProblemToPool {
	my ($self,$course_pool_info,$problem_params, $as_result_set) = @_;

	my $pool = $self->getProblemPool($course_pool_info,1);

	croak "The problem pool does not exist" unless defined($pool);

	my $course_rs = $self->result_source->schema->resultset("Course");
	my $course = $course_rs->find({course_id => $pool->course_id});

	## determine if $problem_params is an arrayref or hashref

	if (reftype($problem_params) eq "ARRAY") {

	} elsif (reftype($problem_params) eq "HASH" ) {
		my $search_params = {%$problem_params};
		$search_params->{course_id} = $pool->course_id;
		my $prob_db = $self->find($search_params,{prefetch => [qw/courses/]});
		# dd {$prob_db->get_columns};
		## if the problem isn't already in the database, add it:
		unless (defined($prob_db)) {
			# my $prob_to_add = $problem_rs->new($problem_params);

			# $course_rs->add_to_problems($problem_params);
		}
	}


	my $pool_problem_rs = $self->result_source->schema->resultset("ProblemPool");
	my $pool_problem = $pool_problem_rs->new($problem_params);



}

sub getPoolProblem {
	my ($self,$course_pool_info,$problem_params, $as_result_set) = @_;
}


1;
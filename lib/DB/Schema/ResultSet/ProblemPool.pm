package DB::Schema::ResultSet::ProblemPool;

use strict;
use warnings;
use feature 'signatures';
no warnings qw(experimental::signatures);

use base 'DBIx::Class::ResultSet';

use Try::Tiny;
use Clone qw/clone/;

use DB::Utils qw/getCourseInfo getPoolInfo getPoolProblemInfo/;

use Exception::Class (
	'DB::Exception::PoolNotInCourse',      'DB::Exception::PoolAlreadyInCourse',
	'DB::Exception::PoolProblemNotInPool', 'DB::Exception::ParametersNeeded'
);

=head1 DESCRIPTION

This is the functionality of a Course in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for anything on the
global courses.

=head2 getAllProblemPools

This gets a list of all problems stored in the database in the C<problem_pool> table.

=head3 input

C<as_result_set>, a boolean if the return is to be a result_set

=head3 output

An array of courses as a C<DBIx::Class::ResultSet::Course> object
if C<$args{as_result_set}> is true.  Otherwise an array of hash_ref.

=cut

sub getAllProblemPools ($self, %args) {
	my @problem_pools = $self->search({});
	return @problem_pools if $args{as_result_set};
	return map {
		{ $_->get_inflated_columns, course_name => $_->courses->course_name };
	} @problem_pools;
}

=head2 getProblemPools

Get all problem pools for a given course

=cut

sub getProblemPools ($self, %args) {
	my $course = $self->rs('Course')->getCourse(info => $args{info}, as_result_set => 1);

	my @pools = $self->search(
		{
			'courses.course_id' => $course->course_id
		},
		{
			join => [qw/courses/]
		}
	);

	return @pools if $args{as_result_set};
	return map {
		{ $_->get_inflated_columns };
	} @pools;
}

# CRUD for a single ProblemPool

=head2 getProblemPool

Get a single problem pool for a given course

=cut

sub getProblemPool ($self, %args) {
	my $course = $self->rs('Course')->getCourse(info => getCourseInfo($args{info}), as_result_set => 1);

	my $search_info = getPoolInfo($args{info});
	$search_info->{'courses.course_id'} = $course->course_id;

	my $pool = $self->find($search_info, { join => [qw/courses/] });

	unless ($pool) {
		my $course_name = $course->course_name;

		DB::Exception::PoolNotInCourse->throw(
			message => "The pool with name \{$args{info}->{pool_name}} is not in the course $course_name");
	}
	return $pool if $args{as_result_set};
	return { $pool->get_columns };
}

=head2 addProblemPool

Add a problem pool for a given course

=cut

sub addProblemPool ($self, %args) {
	my $course = $self->rs('Course')->getCourse(info => getCourseInfo($args{params}), as_result_set => 1);

	DB::Exception::ParametersNeeded->throw(message => 'The pool_name is missing from the parameters')
		unless defined($args{params}->{pool_name});

	my $existing_pool = $self->find(
		{
			'courses.course_id' => $course->course_id,
			pool_name           => $args{params}->{pool_name}
		},
		{ prefetch => [qw/courses/] }
	);

	DB::Exception::PoolAlreadyInCourse->throw(
		message => 'The problem pool '
			. (
			$args{info}->{pool_name} || $args{params}->{pool_name}
			? ' with name ' . ($args{info}->{pool_name} // $args{params}->{pool_name})
			: ' with id ' . $args{info}->{problem_pool_id}
			)
			. " is already defined in the course $course->course_name"
	) if defined($existing_pool);

	my $params = clone $args{params};
	# Delete some fields that may be passed in but are not in the database
	for my $key (qw/course_name course_id/) {
		delete $params->{$key} if defined $params->{$key};
	}

	# need to check for valid parameters.
	my $pool_to_add = $self->new($params);

	my $problem_pool = $course->add_to_problem_pools($params);

	return $problem_pool if $args{as_result_set};
	return { $problem_pool->get_columns };
}

=head2 updateProblemPool

updates the parameters of an existing problem pool

=cut

sub updateProblemPool ($self, %args) {

	my $pool = $self->getProblemPool(info => $args{info}, as_result_set => 1);

	DB::Excpetion::PoolNotInCourse->throw(
		message => 'The problem pool '
			. (
			$args{info}->{pool_name} ? " named $args{info}->{pool_name}" : " with id $args{info}->{problem_pool_id}"
			)
			. ' is not in the course '
			. $args{info}->{course_name} ? " named '$args{info}->{course_name}'" : " with id $args{info}->{course_id}"
	) unless defined($pool);

	# create a new problem pool to check for valid fields
	my $pool_params = $self->new($args{params});

	my $updated_pool = $pool->update($args{params});

	return $updated_pool if $args{as_result_set};
	return { $updated_pool->get_columns };
}

=head2 updateProblemPool

updates the parameters of an existing problem pool

=cut

sub deleteProblemPool ($self, %args) {
	my $pool = $self->getProblemPool(info => $args{info}, as_result_set => 1);

	DB::Exception::PoolNotInCourse->throws(error => 'The problem pool does not exist')
		unless defined($pool);

	my $deleted_pool = $pool->delete();

	return $args{as_result_set} ? $deleted_pool : { $deleted_pool->get_columns };
}

#####
#
# CRUD for PoolProblems, that is creating, retrieving, updating and deleting problem to existing ProblemPools
#
####

=head2 getPoolProblem

This gets a single problem out of a ProblemPool.

=head3 arguments

=over

=item * hashref containing

=over

=item - course_id or course_name

=item - problem_pool_id or pool_name

=item - pool_problem_id or library_id or empty

=back

=back

=cut

sub getPoolProblem ($self, %args) {

	my $problem_pool = $self->getProblemPool(info => $args{info}, as_result_set => 1);

	my $pool_problem_info = {};

	try {    # if problem_info was passed in, then parse it.
		$pool_problem_info = getPoolProblemInfo($args{info});
	} catch {    # else just use an empty hash;
		$pool_problem_info = {};
	};

	my @pool_problems = $problem_pool->search_related('pool_problems', $pool_problem_info)->all;

	if (scalar(@pool_problems) == 1) {
		return $args{as_result_set} ? $pool_problems[0] : { $pool_problems[0]->get_inflated_columns };
	} else {     # pick a random problem.
		my $prob = $pool_problems[ rand @pool_problems ];
		return $args{as_result_set} ? $prob : { $prob->get_inflated_columns };
	}
}

=head2 addProblemToPool

This adds a problem as a hashref to an existing problem pool.

=cut

sub addProblemToPool ($self, %args) {

	my $pool   = $self->getProblemPool(info => $args{params}, as_result_set => 1);
	my $params = clone $args{params};
	DB::Excpetion::PoolNotInCourse->throw(message => 'The problem pool '
			. ($params->{pool_name} ? " named $params->{pool_name}" : " with id $params->{problem_pool_id}")
			. ' is not in the course '
			. ($params->{course_name} ? " named $params->{course_name}" : " with id $params->{course_id}"))
		unless defined($pool);

	# Remove some parameters that are not in the UserSet database, but may be passed in.
	for my $key (qw/pool_name problem_pool_id course_name course_id/) {
		delete $params->{$key} if defined $params->{$key};
	}

	my $course = $self->rs('Course')->find({ course_id => $pool->course_id });

	$params->{problem_pool_id} = $pool->problem_pool_id;
	my $pool_problem = $self->rs('PoolProblem')->new($params);

	my $added_problem = $pool->add_to_pool_problems($params);

	return $added_problem if $args{as_result_set};
	return { $added_problem->get_inflated_columns };
}

=head2 updatePoolProblem

updated an existing problem to an existing ProblemPool in a course

=head3 arguments

=over

=item * hashref containing

=over

=item - course_id or course_name

=item - pool_name or problem_pool_id

=item - library_id or ???

=back

=item * hashref containing information about the Problem.

=back

=cut

sub updatePoolProblem ($self, %args) {
	my $prob = $self->getPoolProblem(info => $args{info}, as_result_set => 1);
	DB::Exception::PoolProblemNotInPool->throw(info => $args{info}) unless defined($prob);

	my $prob_to_update = $self->rs('PoolProblem')->new($args{params});

	my $prob2 = $prob->update({ $prob_to_update->get_columns });
	return $prob2 if $args{as_result_set};
	return { $prob2->get_inflated_columns };
}

# just a small subroutine to shorten access to the db.

sub rs ($self, $table) {
	return $self->result_source->schema->resultset($table);
}

1;

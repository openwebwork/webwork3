package DB::Schema::ResultSet::UserProblem;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DB::Utils qw/getCourseInfo getSetInfo getProblemInfo getUserInfo updateAllFields/;

use Clone qw/clone/;
use Data::Dumper;

use Exception::Class (
	'DB::Exception::UserProblemExists',
	'DB::Exception::UserProblemNotFound',
	'DB::Exception::ProblemNotFound'
);

=head1 DESCRIPTION

This is the functionality of a Problem in WeBWorK.  This package is based on
C<DBIx::Class::ResultSet>.  The basics are a CRUD for a UserProblem.

=head2 getAllUserProblems

This gets an array of all UserProblems stored in the database in the C<user_problems> table.

=head3 input

C<$as_result_set>, a boolean if the return is to be a result_set

=head3 output

An array of user problems as a C<DBIx::Class::ResultSet::UserProblem> object
if C<$as_result_set> is true.  Otherwise an array of hash_ref of the fields.
See <DB::Schema::Result::User::Problem> for information on the fields.

=cut

sub getAllUserProblems {
	my ($self, %args) = @_;
	my @user_problems = $self->search({});

	return @user_problems if $args{as_result_set};

	my @all_user_problems = ();
	for my $user_problem (@user_problems) {
		my $params = $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
		push(@all_user_problems, $params);
	}

	return @all_user_problems;
}

=head1 getUserProblems

Get all user problems (or merged user problems) for one course

=cut

sub getUserProblems {
	my ($self, %args) = @_;
	my $course        = $self->rs("Course")->getCourse(info => $args{info}, as_result_set => 1);
	my @user_problems = $self->search(
		{
			'courses.course_id' => $course->course_id
		},
		{
			join => { problems => { problem_set => 'courses' } }
		}
	);

	return @user_problems if $args{as_result_set};

	my @user_problems_to_return = ();
	for my $user_problem (@user_problems) {
		my $params = $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
		push(@user_problems_to_return, $params);
	}
	return @user_problems_to_return;
}

sub getUserProblem {
	my ($self, %args) = @_;
	my $problem = $self->rs("Problem")->getSetProblem(info => $args{info}, as_result_set => 1);
	my $user_set = $self->rs("UserSet")->getUserSet(info => $args{info}, as_result_set => 1);

	my $user_problem = $self->find({
		problem_id  => $problem->problem_id,
		user_set_id => $user_set->user_set_id,
	});

	# if the problem doesn't exist throw a exception unless skip_throw (used)
	# for checking in addUserProblem

	DB::Exception::UserProblemNotFound->throw(message => "The user problem for the course "
			. $user_set->problem_sets->courses->course_name
			. ", problem set "
			. $user_set->problem_sets->set_name
			. " for user "
			. $user_set->course_users->users->username
			. " and problem number "
			. $problem->problem_number
			. " is not found")
		unless $user_problem || $args{skip_throw};

	return $user_problem if $args{as_result_set};

	return $args{merged} ? _mergeUserProblem($user_problem) : _getUserProblem($user_problem);
}

sub addUserProblem {
	my ($self, %args) = @_;

	my $user_problem = $self->getUserProblem(
		info => $args{info},
		skip_throw        => 1,
		as_result_set     => 1
	);

	DB::Exception::UserProblemExists->throw(message => "The user "
			. $user_problem->user_sets->course_users->users->username
			. " already has problem number "
			. $user_problem->problems->problem_number
			. " in set with name "
			. $user_problem->user_sets->problem_sets->set_name)
		if $user_problem;

	my $problem = $self->rs("Problem")->getSetProblem(info => $args{info}, as_result_set => 1);
	my $user_set = $self->rs("UserSet")->getUserSet(info => $args{info}, as_result_set => 1);

	my $params = clone($args{user_problem_params} // {});
	$params->{seed}   = int(10000 * rand()) unless defined $params->{seed};
	$params->{status} = 0;

	my $problem_to_return = $problem->add_to_user_problems({
		problem_id  => $problem->problem_id,
		user_set_id => $user_set->user_set_id,
		%$params
	});

	return $problem if $args{as_result_set};

	return $args{merged} ? _mergeUserProblem($problem_to_return) : _getUserProblem($problem_to_return);

}

# just a small subroutine to shorten access to the db.

sub rs {
	my ($self, $table) = @_;
	return $self->result_source->schema->resultset($table);
}

sub _mergeUserProblem {
	my $user_problem        = shift;
	my $user_problem_fields = _getUserProblem($user_problem);
	delete $user_problem_fields->{user_problem_params};
	my $problem_fields = { $user_problem->problems->get_inflated_columns };
	delete $problem_fields->{problem_params};

	# merge the params (problem_params and user_problem_params)
	my $params = updateAllFields($user_problem->problems->problem_params, $user_problem->user_problem_params);

	# merge the main fields
	my $merged_params = updateAllFields($problem_fields, $user_problem_fields);
	$merged_params->{problem_params} = $params;

	return $merged_params;
}

sub _getUserProblem {
	my $user_problem = shift;
	return {
		$user_problem->get_inflated_columns,
		problem_number => $user_problem->problems->problem_number,
		username       => $user_problem->user_sets->course_users->users->username,
		set_name       => $user_problem->problems->problem_set->set_name,
		course_name    => $user_problem->problems->problem_set->courses->course_name
	};
}

1;

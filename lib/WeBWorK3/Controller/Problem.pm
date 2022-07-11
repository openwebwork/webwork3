package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub getAllProblems ($self) {
	my @problems = $self->schema->resultset('SetProblem')->getProblems(
		info => {
			course_id => int($self->param('course_id'))
		}
	);
	$self->render(json => \@problems);
	return;
}

sub getProblem ($self) {
	my $problem = $self->schema->resultset('SetProblem')->getSetProblem(
		info => {
			course_id      => int($self->param('course_id')),
			set_id         => int($self->param('set_id')),
			set_problem_id => int($self->param('set_problem_id')),
		}
	);
	$self->render(json => $problem);
	return;
}

sub addProblem ($self) {
	my $problem = $self->schema->resultset('SetProblem')->addSetProblem(
		params => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id')),
			%{ $self->req->json }
		}
	);
	$self->render(json => $problem);
	return;
}

sub updateProblem ($self) {
	my $params = $self->req->json;
	# The render_params shouldn't be passed to the database, so delete that field
	delete $params->{render_params} if defined($params->{render_params});
	my $updated_problem = $self->schema->resultset('SetProblem')->updateSetProblem(
		info => {
			course_id      => int($self->param('course_id')),
			set_id         => int($self->param('set_id')),
			set_problem_id => int($self->param('set_problem_id'))
		},
		params => $params
	);
	$self->render(json => $updated_problem);
	return;
}

sub deleteProblem ($self) {
	my $deleted_problem = $self->schema->resultset('SetProblem')->deleteSetProblem(
		info => {
			course_id      => int($self->param('course_id')),
			set_id         => int($self->param('set_id')),
			set_problem_id => int($self->param('set_problem_id'))
		}
	);
	$self->render(json => $deleted_problem);
	return;
}

sub getUserProblemsForSet ($self) {
	my @user_problems = $self->schema->resultset('UserProblem')->getUserProblemsForSet(
		info => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id'))
		}
	);
	$self->render(json => \@user_problems);
	return;
}

sub getUserProblemsForUser ($self) {
	my @user_problems = $self->schema->resultset('UserProblem')->getUserProblemsForUser(
		info => {
			course_id => int($self->param('course_id')),
			user_id   => int($self->param('user_id'))
		}
	);
	$self->render(json => \@user_problems);
	return;
}

sub getUserProblem ($self) {
	my $user_problem = $self->schema->resultset('UserProblem')->getUserProblem(
		info => {
			course_id       => int($self->param('course_id')),
			user_problem_id => int($self->param('user_problem_id'))
		}
	);
	$self->render(json => $user_problem);
	return;
}

sub addUserProblem ($self) {
	my $problem_params = $self->req->json;

	# add the route parameters to the UserProblem to be added.
	$problem_params->{course_id} = int($self->param('course_id'))
		unless defined($problem_params->{course_id}) || defined($problem_params->{course_name});
	$problem_params->{set_id} = int($self->param('set_id'))
		unless $problem_params->{set_id} || $problem_params->{set_name};
	$problem_params->{user_id} = int($self->param('user_id'))
		unless defined($problem_params->{user_id}) || defined($problem_params->{username});

	# Only pass in set_id instead of set_name
	delete $problem_params->{set_name} if defined($problem_params->{set_id});

	# Only pass in user_id instead of username
	delete $problem_params->{username} if defined($problem_params->{user_id});

	# Only pass in problem_number or set_problem_id
	delete $problem_params->{set_problem_id}
		if (defined($problem_params->{set_problem_id}) && $problem_params->{set_problem_id} == 0);

	my $user_problem = $self->schema->resultset('UserProblem')->addUserProblem(params => $problem_params);
	$self->render(json => $user_problem);
	return;
}

sub updateUserProblem ($self) {
	my $problem_params = $self->req->json;

	my $user_problem = $self->schema->resultset('UserProblem')->updateUserProblem(
		info => {
			course_id       => int($self->param('course_id')),
			set_id          => int($self->param('set_id')),
			user_id         => int($self->param('user_id')),
			user_problem_id => int($self->param('user_problem_id'))
		},
		params => $problem_params
	);
	$self->render(json => $user_problem);
	return;
}

sub deleteUserProblem ($self) {
	my $deleted_problem = $self->schema->resultset('UserProblem')->deleteUserProblem(
		info => {
			course_id       => int($self->param('course_id')),
			set_id          => int($self->param('set_id')),
			user_id         => int($self->param('user_id')),
			user_problem_id => int($self->param('user_problem_id'))
		}
	);
	$self->render(json => $deleted_problem);
	return;
}

1;

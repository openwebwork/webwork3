package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub addProblem ($self) {
	my $problem = $self->schema->resultset("Problem")->addSetProblem(
		params => {
			course_id => int($self->param("course_id")),
			set_id    => int($self->param("set_id")),
			%{ $self->req->json }
		}
	);
	$self->render(json => $problem);
	return;
}

sub getAllProblems ($self) {
	my @problems = $self->schema->resultset("Problem")->getProblems(
		info => {
			course_id => int($self->param("course_id"))
		}
	);
	$self->render(json => \@problems);
	return;
}

sub updateProblem ($self) {
	my $params = $self->req->json;
	# The render_params shouldn't be passed to the database, so delete that field
	delete $params->{render_params} if defined($params->{render_params});
	my $updated_problem = $self->schema->resultset("Problem")->updateSetProblem(
		info => {
			course_id  => int($self->param("course_id")),
			set_id     => int($self->param("set_id")),
			problem_id => int($self->param("problem_id"))
		},
		params => $params
	);
	$self->render(json => $updated_problem);
	return;
}

sub deleteProblem ($self) {
	my $deleted_problem = $self->schema->resultset("Problem")->deleteSetProblem(
		info => {
			course_id  => int($self->param("course_id")),
			set_id     => int($self->param("set_id")),
			problem_id => int($self->param("problem_id"))
		}
	);
	$self->render(json => $deleted_problem);
	return;
}

sub getUserProblemsForSet ($self) {
	my @user_problems = $self->schema->resultset("UserProblem")->getUserProblemsForSet(
		info => {
			course_id => int($self->param('course_id')),
			set_id    => int($self->param('set_id'))
		}
	);
	$self->render(json => \@user_problems);
	return;
}

sub getUserProblemsForUser ($self) {
	my @user_problems = $self->schema->resultset("UserProblem")->getUserProblemsForUser(
		info => {
			course_id => int($self->param('course_id')),
			user_id    => int($self->param('user_id'))
		}
	);
	$self->render(json => \@user_problems);
	return;
}

sub addUserProblem ($self) {
	my $problem_params = $self->req->json;
	$problem_params->{course_id} = int($self->param('course_id'))
		unless defined($problem_params->{course_id}) || defined($problem_params->{course_name});
	$problem_params->{set_id} = int($self->param('set_id'))
		unless defined($problem_params->{set_id}) || defined($problem_params->{set_name});
	$problem_params->{user_id} = int($self->param('user_id'))
		unless defined($problem_params->{user_id}) || defined($problem_params->{username});
	my $user_problem = $self->schema->resultset("UserProblem")->addUserProblem(params => $problem_params);
	$self->render(json => $user_problem);
	return;
}

sub deleteUserProblem ($self) {
	my $deleted_problem = $self->schema->resultset("UserProblem")->deleteUserProblem(
		info => {
			course_id  => int($self->param('course_id')),
			set_id     => int($self->param('set_id')),
			user_id    => int($self->param('user_id')),
			problem_id => int($self->param('problem_id'))
		}
	);
	$self->render(json => $deleted_problem);
	return;
}

1;

package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

sub addProblem ($self) {
	my $problem = $self->schema->resultset("Problem")->addSetProblem(
		params=> {
			course_id => int($self->param("course_id")),
			set_id    => int($self->param("set_id"))
			%{$self->req->json}
		});
	$self->render(json => $problem);
	return;
}

sub getAllProblems ($self) {
	my @problems    = $self->schema->resultset("Problem")
		->getProblems(info => {
				course_id => int($self->param("course_id"))
			}
		);
	$self->render(json => \@problems);
	return;
}

sub updateProblem ($self) {
		my $updated_problem = $self->schema->resultset("Problem")->updateSetProblem(
			info => {
				course_id  => int($self->param("course_id")),
				set_id     => int($self->param("set_id")),
				problem_id => int($self->param("problem_id"))
			},
			params => $self->req->json
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
		});
	$self->render(json => $deleted_problem);
	return;
}

1;

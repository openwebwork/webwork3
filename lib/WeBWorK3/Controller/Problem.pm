package WeBWorK3::Controller::Problem;
use warnings;
use strict;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Try::Tiny;
use Mojo::JSON qw/true false/;

sub addProblem ($self) {
	my $course_set_params = {
		course_id => int($self->param("course_id")),
		set_id    => int($self->param("set_id"))
	};

	my $problem = $self->schema->resultset("Problem")->addSetProblem($course_set_params, $self->req->json);
	$self->render(json => $problem);
	return;
}

sub getAllProblems ($self) {
	my $course_info = { course_id => int($self->param("course_id")) };
	my @problems    = $self->schema->resultset("Problem")->getProblems($course_info);
	$self->render(json => \@problems);
	return;
}

sub updateProblem ($self) {
	my $course_set_problem_params = {
		course_id  => int($self->param("course_id")),
		set_id     => int($self->param("set_id")),
		problem_id => int($self->param("problem_id"))
	};

	my $updated_problem =
		$self->schema->resultset("Problem")->updateSetProblem($course_set_problem_params, $self->req->json);
	$self->render(json => $updated_problem);
	return;
}

sub deleteProblem ($self) {
	my $course_set_problem_params = {
		course_id  => int($self->param("course_id")),
		set_id     => int($self->param("set_id")),
		problem_id => int($self->param("problem_id"))
	};
	my $deleted_problem = $self->schema->resultset("Problem")->deleteSetProblem($course_set_problem_params);
	$self->render(json => $deleted_problem);
	return;
}

1;
